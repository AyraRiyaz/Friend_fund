/// Configuration class for API endpoints and app settings
/// Modified for FriendFund Appwrite Function integration
class AppConfig {
  // API Configuration - Production Appwrite Function URL
  static const String baseUrl = 'https://68b699f80025cf96484e.fra.appwrite.run';

  static const String apiVersion = 'v1';

  // API Endpoints
  static const String campaignsEndpoint = '/campaigns';
  static const String contributionsEndpoint = '/contributions';
  static const String usersEndpoint = '/users';
  static const String qrEndpoint = '/qr';
  static const String paymentQrEndpoint = '/payment-qr';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // App Configuration
  static const String appName = 'FriendFund';
  static const String appVersion = '1.0.0';

  // Environment specific configurations
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDebug => !isProduction;

  // Development helpers
  static void debugPrint(String message) {
    if (isDebug) {
      print('[FriendFund Debug] $message');
    }
  }

  // Configuration info
  static String get configInfo =>
      '''
🔧 FriendFund Configuration:
📡 API Mode: Production (Appwrite Function)
🌐 Base URL: $baseUrl
🔗 Appwrite Function URL: $baseUrl
''';
}
