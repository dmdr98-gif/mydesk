// SPDX-License-Identifier: AGPL-3.0-only

class TailscaleEndpoint {
  const TailscaleEndpoint._(this.address, this.port);

  static const defaultPort = 21118;
  final String address;
  final int port;

  String get target => '$address:$port';

  Uri get pairingUri => Uri(
        scheme: 'everywhere',
        host: 'tailscale',
        queryParameters: {'address': address, 'port': port.toString()},
      );

  static TailscaleEndpoint? parse(String value) {
    final text = value.trim();
    if (text.length > 128) return null;
    if (text.startsWith('everywhere://')) {
      final uri = Uri.tryParse(text);
      if (uri == null ||
          uri.authority != 'tailscale' ||
          uri.path.isNotEmpty ||
          uri.hasFragment) {
        return null;
      }
      try {
        final params = uri.queryParametersAll;
        final address = params['address'];
        final port = params['port'];
        if (params.length != 2 || address?.length != 1 || port?.length != 1) {
          return null;
        }
        return _fromParts(address!.single, port!.single);
      } on FormatException {
        return null;
      }
    }

    final parts = text.split(':');
    if (parts.length > 2) return null;
    return _fromParts(
      parts.first,
      parts.length == 2 ? parts.last : defaultPort.toString(),
    );
  }

  static TailscaleEndpoint? _fromParts(String address, String portText) {
    final octets = address.split('.');
    if (octets.length != 4 || octets.first != '100') return null;
    final prefix = _parseDecimal(octets[1], 127);
    if (prefix == null || prefix < 64) return null;
    if (_parseDecimal(octets[2], 255) == null ||
        _parseDecimal(octets[3], 255) == null ||
        address == '100.100.100.100') {
      return null;
    }
    final port = _parseDecimal(portText, 65535);
    if (port == null || port == 0) return null;
    return TailscaleEndpoint._(address, port);
  }

  static int? _parseDecimal(String value, int max) {
    if (!RegExp(r'^(0|[1-9][0-9]{0,4})$').hasMatch(value)) return null;
    final number = int.parse(value);
    return number <= max ? number : null;
  }
}
