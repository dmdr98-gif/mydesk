// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_hbb/common/tailscale_endpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pairing QR preserves a host and a custom port', () {
    final host = TailscaleEndpoint.parse('100.127.0.2:22222')!;
    expect(TailscaleEndpoint.parse(host.pairingUri.toString())?.target,
        '100.127.0.2:22222');
    expect(TailscaleEndpoint.parse(' 100.64.255.1 ')?.target,
        '100.64.255.1:21118');
  });

  test('pairing accepts only a Tailscale IPv4 endpoint', () {
    for (final value in [
      '192.168.1.20',
      '100.63.1.2',
      '100.128.1.2',
      '100.64.256.2',
      '100.64.01.2',
      '100.100.100.100',
      '100.64.1.2:0',
      '100.64.1.2:65536',
      '100.64.1.2:21118\\n',
      'host.example.com:21118',
      'everywhere://tailscale?address=100.64.1.2',
      'everywhere://tailscale?address=100.64.1.2&port=1&port=2',
      'everywhere://tailscale?address=100.64.1.2&port=1&key=example',
      'everywhere://tailscale?address=100.64.1.2&port=%0A1',
      'everywhere://user@tailscale?address=100.64.1.2&port=1',
      'everywhere://tailscale/path?address=100.64.1.2&port=1',
      'everywhere://tailscale?address=100.64.1.2&port=1#fragment',
    ]) {
      expect(TailscaleEndpoint.parse(value), isNull, reason: value);
    }
  });
}
