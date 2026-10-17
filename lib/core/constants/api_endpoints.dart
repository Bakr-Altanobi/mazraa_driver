abstract final class ApiEndpoints {
  static const baseUrl = String.fromEnvironment(
    'MAZRAA_API_URL',
    defaultValue: 'https://mzraa.runasp.net/',
  );

  static const login = 'api/Auth/login';
  static const refresh = 'api/Auth/refresh';
  static const logout = 'api/Auth/logout';
  static const drivers = 'api/Drivers';
  static const shipments = 'api/Shipments';
  static const wallet = 'api/wallets/me';
  static const walletTransactions = 'api/wallets/transactions';
  static const notifications = 'api/notifications';
  static const unreadNotifications = 'api/notifications/unread-count';
}

abstract final class AppEnvironment {
  static const mapsEnabled = bool.fromEnvironment(
    'ENABLE_GOOGLE_MAPS',
    // Native map key is provided through Android local.properties / MAPS_API_KEY,
    // or GMSApiKey on iOS. Disable the platform view in CI smoke renders.
    defaultValue: !bool.fromEnvironment('CI_SMOKE_HOME'),
  );
  static const testDriverEmail = String.fromEnvironment('DRIVER_TEST_EMAIL');
  static const testDriverPassword = String.fromEnvironment(
    'DRIVER_TEST_PASSWORD',
  );
}
