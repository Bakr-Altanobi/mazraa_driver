import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_referral_links.dart';

void main() {
  test('temporary first-party invitation link retains safe server referral code', () {
    final url = driverInviteUri('DRV-2026_9');
    expect(url.scheme, 'https');
    expect(url.host, 'mzraa.runasp.net');
    expect(url.path, '/driver-invite/index.html');
    expect(url.queryParameters['ref'], 'DRV-2026_9');
    expect(driverInvitePage, 'https://mzraa.runasp.net/driver-invite/index.html');
  });

  test('malicious or malformed referral code never changes the landing route', () {
    final url = driverInviteUri('https://other.example/?drop=1');
    expect(url.host, 'mzraa.runasp.net');
    expect(url.path, '/driver-invite/index.html');
    expect(url.queryParameters.containsKey('ref'), false);
  });

  test('WhatsApp shares branded page URL and the exact referral code', () {
    final message = driverInviteMessage('DRV-81');
    expect(message, contains('DRV-81'));
    expect(message, contains('mzraa.runasp.net/driver-invite/index.html'));
    final uri = driverWhatsAppInviteUri(message);
    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.queryParameters['text'], message);
  });
}
