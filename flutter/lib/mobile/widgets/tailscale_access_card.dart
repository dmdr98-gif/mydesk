// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common.dart';
import '../../common/tailscale_endpoint.dart';
import '../../models/platform_model.dart';
import '../pages/scan_page.dart';

class TailscaleAccessCard extends StatefulWidget {
  const TailscaleAccessCard({Key? key}) : super(key: key);

  @override
  State<TailscaleAccessCard> createState() => _TailscaleAccessCardState();
}

class _TailscaleAccessCardState extends State<TailscaleAccessCard> {
  static const _hostOption = 'tailscale-home-host';
  TailscaleEndpoint? _host;
  bool _connecting = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _host = TailscaleEndpoint.parse(bind.mainGetLocalOption(key: _hostOption));
  }

  Future<void> _openTailscale() async {
    try {
      if (await gFFI.invokeMethod('open_tailscale')) return;
      if (!mounted) return;
      final install = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(translate('Install Tailscale')),
          content: Text(translate(
              'Install or open Tailscale on both devices and sign in with the same account. Approve the VPN request in the official Tailscale app, then return here.')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(translate('Cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(translate('Open Play Store'))),
          ],
        ),
      );
      if (install != true) return;
      final opened = await launchUrl(
        Uri.https('play.google.com', '/store/apps/details',
            {'id': 'com.tailscale.ipn'}),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _status = 'Could not open Tailscale or Play Store');
      }
    } catch (e) {
      debugPrint('Failed to open Tailscale: $e');
      if (mounted) {
        setState(() => _status = 'Could not open Tailscale or Play Store');
      }
    }
  }

  Future<void> _pairHost() async {
    final input = TextEditingController(text: _host?.target ?? '');
    String? error;
    final route = DialogRoute<TailscaleEndpoint>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, updateDialog) {
        return AlertDialog(
          title: Text(translate('Pair home PC')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(translate(
                    'Scan or paste the pairing code shown on your PC.')),
                const SizedBox(height: 12),
                TextField(
                  controller: input,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText:
                        translate('PC Tailscale address or pairing code'),
                    hintText: '100.64.0.1:21118',
                    errorText: error == null ? null : translate(error!),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  TextButton.icon(
                    icon: const Icon(Icons.paste),
                    label: Text(translate('Paste')),
                    onPressed: () async {
                      final data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (!context.mounted || data?.text == null) return;
                      input.text = data!.text!;
                      updateDialog(() => error = null);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(translate('Scan QR')),
                    onPressed: () async {
                      final code = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ScanPage(returnResult: true)));
                      if (!context.mounted || code == null) return;
                      input.text = code;
                      updateDialog(() => error = null);
                    },
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translate('Cancel'))),
            TextButton(
              onPressed: () {
                final value = TailscaleEndpoint.parse(input.text);
                if (value == null) {
                  updateDialog(() =>
                      error = 'Invalid Tailscale address or pairing code');
                  return;
                }
                Navigator.pop(context, value);
              },
              child: Text(translate('Save')),
            ),
          ],
        );
      }),
    );
    final host = await Navigator.of(context).push(route);
    await route.completed;
    input.dispose();
    if (host == null || !mounted) return;
    try {
      await bind.mainSetLocalOption(key: _hostOption, value: host.target);
      if (mounted) {
        setState(() {
          _host = host;
          _status = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to save Tailscale home PC: $e');
      if (mounted) setState(() => _status = 'Failed');
    }
  }

  Future<bool> _hostIsReachable(TailscaleEndpoint host) async {
    Socket? socket;
    try {
      if (await _vpnStatus() != 'cgnat-vpn') return false;
      socket = await Socket.connect(host.address, host.port,
          timeout: const Duration(seconds: 1));
      return true;
    } on SocketException {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  Future<String?> _vpnStatus() =>
      gFFI.invokeMethodWithResult<String>('tailscale_vpn_status');

  Future<bool> _proxyIsConfigured() async {
    final socks = await bind.mainGetSocks();
    return socks.isNotEmpty && socks.first.trim().isNotEmpty;
  }

  Future<void> _connectHost() async {
    final host = _host;
    if (host == null || _connecting) return;
    setState(() {
      _connecting = true;
      _status = 'Connecting to home PC';
    });
    try {
      if (await _proxyIsConfigured()) {
        if (mounted) {
          setState(() => _status =
              'Turn off the SOCKS5 proxy in settings before using Tailscale remote access.');
        }
        return;
      }
      final vpnStatus = await _vpnStatus();
      if (vpnStatus != 'cgnat-vpn') {
        if (!mounted) return;
        // Android cannot identify another app's VPN owner. Leave an existing
        // VPN in place and let the user choose Tailscale in its own app.
        if (vpnStatus == 'other-vpn') {
          setState(() => _status =
              'A VPN is already active. Open Tailscale to check the connection, then try again.');
          return;
        }
        if (vpnStatus != 'none') {
          setState(() => _status =
              'Tailscale VPN connection could not be verified. Open Tailscale and try again.');
          return;
        }
        if (!await gFFI.invokeMethod('connect_tailscale')) {
          if (mounted) {
            setState(() => _status = null);
            await _openTailscale();
          }
          return;
        }
      }
      final wait = Stopwatch()..start();
      while (mounted && wait.elapsed < const Duration(seconds: 12)) {
        if (await _hostIsReachable(host) &&
            mounted &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          if (await _proxyIsConfigured()) {
            if (mounted) {
              setState(() => _status =
                  'Turn off the SOCKS5 proxy in settings before using Tailscale remote access.');
            }
            return;
          }
          if (await _vpnStatus() != 'cgnat-vpn') continue;
          if (!mounted) return;
          if (WidgetsBinding.instance.lifecycleState !=
              AppLifecycleState.resumed) continue;
          setState(() => _status = null);
          connect(context, host.target);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (mounted) {
        setState(() => _status =
            'PC is not reachable. Check Tailscale on both devices and direct IP access on the PC, then try again.');
      }
    } catch (e) {
      debugPrint('Failed to connect Tailscale home PC: $e');
      if (mounted) setState(() => _status = 'Failed');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _forgetHost() async {
    try {
      await bind.mainSetLocalOption(key: _hostOption, value: '');
      if (mounted) {
        setState(() {
          _host = null;
          _status = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to forget Tailscale home PC: $e');
      if (mounted) setState(() => _status = 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(translate('Tailscale remote access'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(translate(
              'Install or open Tailscale on both devices and sign in with the same account. Approve the VPN request in the official Tailscale app, then return here.')),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: _connecting ? null : _openTailscale,
                icon: const Icon(Icons.vpn_key),
                label: Text(translate('Open Tailscale'))),
            TextButton.icon(
                onPressed: _connecting ? null : _pairHost,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(translate('Pair home PC'))),
          ]),
          if (_host != null) ...[
            const Divider(),
            Text('${translate('Saved home PC')}: ${_host!.target}'),
            Wrap(spacing: 8, children: [
              ElevatedButton.icon(
                  onPressed: _connecting ? null : _connectHost,
                  icon: const Icon(Icons.connected_tv),
                  label: Text(translate('Connect'))),
              TextButton(
                  onPressed: _connecting ? null : _forgetHost,
                  child: Text(translate('Forget home PC'))),
            ]),
          ],
          if (_connecting) const LinearProgressIndicator(),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(translate(_status!)),
          ],
        ]),
      ),
    );
  }
}
