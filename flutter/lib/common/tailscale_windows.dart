// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WindowsTailscaleStatus {
  final bool installed;
  final String? backendState;
  final String? ipv4;
  final String? error;

  const WindowsTailscaleStatus({
    required this.installed,
    this.backendState,
    this.ipv4,
    this.error,
  });

  bool get connected => backendState == 'Running' && ipv4 != null;

  factory WindowsTailscaleStatus.fromJson(Map<String, dynamic> json) {
    final state = json['BackendState'];
    if (state is! String) {
      throw const FormatException('Missing Tailscale backend state');
    }
    final self = json['Self'];
    final addresses = self is Map && self['TailscaleIPs'] is List
        ? self['TailscaleIPs']
        : json['TailscaleIPs'];
    String? ipv4;
    if (addresses is List) {
      for (final address in addresses) {
        if (address is! String) continue;
        final parsed = InternetAddress.tryParse(address);
        if (parsed == null || parsed.type != InternetAddressType.IPv4) continue;
        final bytes = parsed.rawAddress;
        if (bytes[0] == 100 && bytes[1] >= 64 && bytes[1] <= 127) {
          ipv4 = parsed.address;
          break;
        }
      }
    }
    return WindowsTailscaleStatus(
        installed: true, backendState: state, ipv4: ipv4);
  }
}

class WindowsTailscaleAction {
  final bool started;
  final Uri? loginUrl;
  final String? error;

  const WindowsTailscaleAction({
    required this.started,
    this.loginUrl,
    this.error,
  });

  factory WindowsTailscaleAction.fromUpOutput(String output,
      {required int exitCode}) {
    if (exitCode == 0) {
      return const WindowsTailscaleAction(started: true);
    }
    // `up --json` emits multiple JSON objects while authentication is pending.
    final matches =
        RegExp(r'"AuthURL"\s*:\s*("(?:[^"\\]|\\.)*")').allMatches(output);
    for (final match in matches) {
      try {
        final url = Uri.tryParse(jsonDecode(match.group(1)!) as String);
        if (url != null &&
            url.scheme == 'https' &&
            url.host == 'login.tailscale.com' &&
            url.port == 443 &&
            url.userInfo.isEmpty &&
            !url.hasFragment &&
            url.path.startsWith('/a/')) {
          return WindowsTailscaleAction(started: true, loginUrl: url);
        }
      } on FormatException {
        // Do not expose CLI output or authentication URLs in error messages.
      }
    }
    return const WindowsTailscaleAction(
      started: false,
      error: 'Open the Tailscale app to finish connecting, then refresh.',
    );
  }
}

class WindowsTailscale {
  static const installUrl = 'https://tailscale.com/download/windows';
  static const _installDirectories = [
    r'C:\Program Files\Tailscale',
    r'C:\Program Files (x86)\Tailscale',
  ];

  const WindowsTailscale();

  Future<String?> _executable(String name) async {
    if (!Platform.isWindows) return null;
    // Only standard administrator-protected install directories, never PATH.
    for (final directory in _installDirectories) {
      final path = '$directory\\$name';
      if (await File(path).exists()) return path;
    }
    return null;
  }

  Future<WindowsTailscaleStatus> readStatus() async {
    try {
      final executable = await _executable('tailscale.exe');
      if (executable == null) {
        return const WindowsTailscaleStatus(installed: false);
      }
      final result =
          await _run(executable, ['status', '--json', '--peers=false']);
      if (result.exitCode != 0) {
        return const WindowsTailscaleStatus(
          installed: true,
          error:
              'Open the Tailscale app and check that its service is running.',
        );
      }
      final json = jsonDecode(result.output);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid Tailscale status');
      }
      return WindowsTailscaleStatus.fromJson(json);
    } on TimeoutException {
      return const WindowsTailscaleStatus(
          installed: true, error: 'Tailscale did not respond. Try refreshing.');
    } on ProcessException {
      return const WindowsTailscaleStatus(
          installed: true,
          error: 'The Tailscale command could not be started.');
    } on FileSystemException {
      return const WindowsTailscaleStatus(
          installed: false,
          error: 'The Tailscale installation could not be checked.');
    } on FormatException {
      return const WindowsTailscaleStatus(
          installed: true, error: 'Tailscale returned an unreadable status.');
    }
  }

  Future<WindowsTailscaleAction> connect() async {
    try {
      final executable = await _executable('tailscale.exe');
      if (executable == null) {
        return const WindowsTailscaleAction(
            started: false, error: 'Install Tailscale, then refresh.');
      }
      // These flags control output/waiting only. Never reset existing settings,
      // change accounts, or supply authentication keys on the user's behalf.
      final result = await _run(
        executable,
        ['up', '--json', '--timeout=10s'],
        timeout: const Duration(seconds: 15),
      );
      return WindowsTailscaleAction.fromUpOutput(result.output,
          exitCode: result.exitCode);
    } on TimeoutException {
      return const WindowsTailscaleAction(
          started: false, error: 'Tailscale did not respond. Try refreshing.');
    } on ProcessException {
      return const WindowsTailscaleAction(
          started: false, error: 'The Tailscale command could not be started.');
    } on FileSystemException {
      return const WindowsTailscaleAction(
          started: false,
          error: 'The Tailscale installation could not be checked.');
    }
  }

  Future<WindowsTailscaleAction> openApp() async {
    try {
      final executable = await _executable('tailscale-ipn.exe');
      if (executable == null) {
        return const WindowsTailscaleAction(
            started: false,
            error: 'Open Tailscale from the Windows Start menu.');
      }
      await Process.start(executable, [],
          runInShell: false, mode: ProcessStartMode.detached);
      return const WindowsTailscaleAction(started: true);
    } on ProcessException {
      return const WindowsTailscaleAction(
          started: false, error: 'Open Tailscale from the Windows Start menu.');
    } on FileSystemException {
      return const WindowsTailscaleAction(
          started: false,
          error: 'The Tailscale installation could not be checked.');
    }
  }

  Future<_TailscaleCommandResult> _run(
      String executable, List<String> arguments,
      {Duration timeout = const Duration(seconds: 8)}) async {
    final process =
        await Process.start(executable, arguments, runInShell: false);
    final completion = Future.wait<Object>([
      process.exitCode,
      process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join(),
      process.stderr.drain<String>(''),
    ]);
    try {
      final result = await completion.timeout(timeout);
      return _TailscaleCommandResult(result[0] as int, result[1] as String);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      // Do not leave a stalled CLI process waiting for a browser login forever.
      await completion.timeout(const Duration(seconds: 2),
          onTimeout: () => <Object>[-1, '', '']);
      rethrow;
    }
  }
}

class _TailscaleCommandResult {
  final int exitCode;
  final String output;

  const _TailscaleCommandResult(this.exitCode, this.output);
}
