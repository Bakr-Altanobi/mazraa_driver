/// Temporary first-party driver invitation landing page.
/// It is hosted by Ecommerce_Api (on deployment), with Open Graph preview
/// image created from the actual Mazraa brand mark.
const driverInvitePage = 'https://mzraa.runasp.net/driver-invite/index.html';

Uri driverInviteUri(String? referralCode) {
  final safe = referralCode?.trim();
  return Uri.https(
    'mzraa.runasp.net',
    '/driver-invite/index.html',
    safe != null && RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(safe)
        ? {'ref': safe}
        : null,
  );
}

String driverInviteMessage(String? referralCode) {
  final code = referralCode?.trim();
  final codeLine = code == null || code.isEmpty ? '' : ' رمز دعوتي: $code.';
  return '🌿 انضم إلى مزرعتي للسائق!$codeLine '
      'شاهد صفحة التطبيق المؤقتة: ${driverInviteUri(code)}';
}

/// WhatsApp receives a real HTTPS landing-page URL, not a placeholder store
/// link or a data-URL icon. Link preview depends on server deployment.
Uri driverWhatsAppInviteUri(String message) =>
    Uri.https('wa.me', '/', {'text': message});
