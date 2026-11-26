// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/tailscale_windows.dart';

void main() {
  test('uses the local tailnet IPv4 only while backend is running', () {
    final running = WindowsTailscaleStatus.fromJson({
      'BackendState': 'Running',
      'Self': {
        'TailscaleIPs': ['fd7a:115c:a1e0::1234', '100.88.1.2'],
      },
      'Peer': {
        'other-device': {
          'TailscaleIPs': ['100.88.1.3'],
        },
      },
    });
    expect(running.installed, isTrue);
    expect(running.connected, isTrue);
    expect(running.ipv4, '100.88.1.2');
    final stopped = WindowsTailscaleStatus.fromJson({
      'BackendState': 'Stopped',
      'Self': {
        'TailscaleIPs': ['100.88.1.2'],
      },
    });
    expect(stopped.connected, isFalse);
  });

  test('rejects invalid state and does not publish an unrelated local address',
      () {
    expect(() => WindowsTailscaleStatus.fromJson({'BackendState': null}),
        throwsFormatException);
    for (final address in ['192.168.1.2', '100.63.1.2', '100.128.1.2']) {
      final status = WindowsTailscaleStatus.fromJson({
        'BackendState': 'Running',
        'Self': {
          'TailscaleIPs': [address],
        },
      });
      expect(status.ipv4, isNull);
      expect(status.connected, isFalse);
    }
  });

  test('only returns the official device login URL from pending CLI output',
      () {
    final pending = WindowsTailscaleAction.fromUpOutput(
      '{"AuthURL":"https://login.tailscale.com/a/device-token",'
      '"BackendState":"NeedsLogin"}\n'
      '{"BackendState":"NeedsLogin","Error":"timeout"}',
      exitCode: 1,
    );
    expect(pending.started, isTrue);
    expect(pending.loginUrl.toString(),
        'https://login.tailscale.com/a/device-token');
    for (final url in [
      'http://login.tailscale.com/a/token',
      'https://login.tailscale.com.evil.invalid/a/token',
      'https://custom-tailnet.invalid/a/token',
      'https://user@login.tailscale.com/a/token',
      'https://login.tailscale.com:8443/a/token',
    ]) {
      final action = WindowsTailscaleAction.fromUpOutput('{"AuthURL":"$url"}',
          exitCode: 1);
      expect(action.loginUrl, isNull);
      expect(action.started, isFalse);
    }
    expect(
        WindowsTailscaleAction.fromUpOutput('{"BackendState":"Running"}',
                exitCode: 0)
            .started,
        isTrue);
  });
}
