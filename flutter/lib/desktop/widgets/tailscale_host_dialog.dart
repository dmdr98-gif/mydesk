// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/tailscale_endpoint.dart';
import 'package:flutter_hbb/common/tailscale_windows.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showTailscaleHostDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _TailscaleHostDialog(),
  );
}

class _TailscaleHostDialog extends StatefulWidget {
  const _TailscaleHostDialog();

  @override
  State<_TailscaleHostDialog> createState() => _TailscaleHostDialogState();
}

class _TailscaleHostDialogState extends State<_TailscaleHostDialog> {
  final _tailscale = const WindowsTailscale();
  WindowsTailscaleStatus? _status;
  TailscaleEndpoint? _endpoint;
  Timer? _refreshTimer;
  bool _busy = false;
  bool _refreshing = false;
  bool _directEnabled = false;
  bool _serviceStopped = true;
  bool _securityUnlocked = false;
  String? _error;

  bool get _working => _busy || _refreshing;
  bool get _canShare =>
      _status?.connected == true &&
      _endpoint != null &&
      _directEnabled &&
      !_serviceStopped;

  @override
  void initState() {
    super.initState();
    _securityUnlocked = !bind.mainIsInstalled();
    _refresh();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_working || !mounted) return;
    setState(() => _refreshing = true);
    try {
      final status = await _tailscale.readStatus();
      final directEnabled = await mainGetBoolOption(kOptionDirectServer);
      final serviceStopped = await mainGetBoolOption(kOptionStopService);
      final configuredPort =
          int.tryParse(await bind.mainGetOption(key: kOptionDirectAccessPort));
      final port = configuredPort == null || configuredPort <= 0
          ? TailscaleEndpoint.defaultPort
          : configuredPort;
      final endpoint = status.ipv4 == null
          ? null
          : TailscaleEndpoint.parse('${status.ipv4}:$port');
      if (!mounted) return;
      setState(() {
        if (_error == 'Could not check remote access settings') _error = null;
        _status = status;
        _directEnabled = directEnabled;
        _serviceStopped = serviceStopped;
        _endpoint = endpoint;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = null;
          _endpoint = null;
          _error = 'Could not check remote access settings';
        });
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_working) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not complete the action. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
    }
  }

  Future<void> _openTailscale() => _perform(() async {
        final result = await _tailscale.openApp();
        if (!result.started) {
          throw StateError('Tailscale did not open');
        }
      });

  Future<void> _connectTailscale() => _perform(() async {
        final result = await _tailscale.connect();
        final loginUrl = result.loginUrl;
        if (loginUrl != null) {
          if (!await launchUrl(loginUrl,
              mode: LaunchMode.externalApplication)) {
            throw StateError('Tailscale sign-in did not open');
          }
        } else if (!result.started) {
          throw StateError('Tailscale did not connect');
        }
      });

  Future<void> _installTailscale() => _perform(() async {
        if (!await launchUrl(Uri.parse(WindowsTailscale.installUrl),
            mode: LaunchMode.externalApplication)) {
          throw StateError('Tailscale download did not open');
        }
      });

  Future<void> _unlockSecurity() async {
    final unlockPin = bind.mainGetUnlockPin();
    if (unlockPin.isNotEmpty && !isUnlockPinDisabled()) {
      checkUnlockPinDialog(unlockPin, () {
        if (mounted) setState(() => _securityUnlocked = true);
      });
    } else {
      await _perform(() async {
        if (await callMainCheckSuperUserPermission() && mounted) {
          setState(() => _securityUnlocked = true);
        }
      });
    }
  }

  Future<void> _enableDirectAccess() => _perform(() async {
        if (!_securityUnlocked || isOptionFixed(kOptionDirectServer)) return;
        await mainSetBoolOption(kOptionDirectServer, true);
        if (!await mainGetBoolOption(kOptionDirectServer)) {
          throw StateError('Direct IP setting was not saved');
        }
      });

  Future<void> _startService() => _perform(() async {
        if (isOptionFixed(kOptionStopService)) return;
        await start_service(true);
        if (await mainGetBoolOption(kOptionStopService)) {
          throw StateError('Service remains stopped');
        }
      });

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    showToast(translate('Copied'));
  }

  String get _tailscaleStatus {
    final status = _status;
    if (status == null) return 'Checking Tailscale';
    if (!status.installed) return 'Tailscale is not installed';
    if (status.connected) return 'Connected';
    if (status.backendState == 'NeedsMachineAuth') {
      return 'Approve this device in Tailscale';
    }
    if (status.error != null) return 'Open Tailscale to check its status';
    return 'Sign in or connect Tailscale';
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translate(title),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final directFixed = isOptionFixed(kOptionDirectServer);
    final endpoint = _endpoint;
    return AlertDialog(
      title: Text(translate('Tailscale remote access')),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(translate(
                  'Connect both devices to the same Tailscale network.')),
              _section('Connect this PC', [
                Row(children: [
                  Icon(status?.connected == true
                      ? Icons.check_circle_outline
                      : Icons.vpn_key_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(translate(_tailscaleStatus))),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (status != null && !status.installed)
                    ElevatedButton(
                      onPressed: _working ? null : _installTailscale,
                      child: Text(translate('Install Tailscale')),
                    ),
                  if (status?.installed == true && !status!.connected)
                    ElevatedButton(
                      onPressed: _working ? null : _connectTailscale,
                      child: Text(translate('Sign in or connect Tailscale')),
                    ),
                  if (status?.installed == true)
                    OutlinedButton(
                      onPressed: _working ? null : _openTailscale,
                      child: Text(translate('Open Tailscale')),
                    ),
                ]),
              ]),
              const Divider(),
              _section('Allow remote access', [
                if (_directEnabled)
                  Text(translate('Direct IP access is enabled')),
                if (!_directEnabled) ...[
                  Text(translate(
                      'Direct IP access uses your existing password and approval settings.')),
                  const SizedBox(height: 8),
                  if (directFixed)
                    Text(translate(
                        'This setting is managed by your administrator'))
                  else if (!_securityUnlocked)
                    OutlinedButton.icon(
                      onPressed: _working ? null : _unlockSecurity,
                      icon: const Icon(Icons.lock_open),
                      label: Text(translate('Unlock Security Settings')),
                    )
                  else
                    ElevatedButton(
                      onPressed: _working ? null : _enableDirectAccess,
                      child: Text(translate('Enable direct IP access')),
                    ),
                ],
                if (_serviceStopped) ...[
                  const SizedBox(height: 8),
                  Text(translate('Service is not running')),
                  OutlinedButton(
                    onPressed: _working || isOptionFixed(kOptionStopService)
                        ? null
                        : _startService,
                    child: Text(translate('Start service')),
                  ),
                ],
                const SizedBox(height: 8),
                Text(translate('Keep everywhere running on this PC.')),
              ]),
              const Divider(),
              _section('Pair another device', [
                if (_canShare && endpoint != null) ...[
                  Text(translate('Your home PC address')),
                  SelectableText(endpoint.target,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Center(
                    child: QrImageView(
                      data: endpoint.pairingUri.toString(),
                      backgroundColor: Colors.white,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(translate(
                      'Scan this code in everywhere on your phone, or copy the address for another PC.')),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: () => _copy(endpoint.pairingUri.toString()),
                      icon: const Icon(Icons.link),
                      label: Text(translate('Copy pairing link')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copy(endpoint.target),
                      icon: const Icon(Icons.copy),
                      label: Text(translate('Copy address')),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(translate(
                      'If the connection is blocked, allow this port through Windows Firewall for your Tailscale network.')),
                ] else
                  Text(translate(
                      'Connect Tailscale and enable remote access to show the pairing code.')),
                if (status?.connected == true && endpoint == null)
                  Text(translate(
                      'Check the Tailscale address and direct IP port in settings.')),
              ]),
              if (_error != null)
                Text(translate(_error!),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_working) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : _refresh,
          child: Text(translate('Refresh')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(translate('Close')),
        ),
      ],
    );
  }
}
