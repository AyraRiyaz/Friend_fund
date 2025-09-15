/// Configuration class for API endpoints and app settings
/// Modified for FriendFund HTTP backend integration
class AppConfig {
  // Deployment Configuration
  static const bool useLocalhost = false; // Set to true for local development

  // API Configuration - dual mode (localhost + Appwrite function)
  static const String localhostUrl = 'http://localhost:3000';
  static const String appwriteFunctionUrl =
      'https://68b699f80025cf96484e.fra.appwrite.run';

  // Dynamic base URL based on deployment mode
  // When useLocalhost = true: Uses local HTTP server at localhost:3000
  // When useLocalhost = false: Uses deployed Appwrite function
  static String get baseUrl =>
      useLocalhost ? localhostUrl : appwriteFunctionUrl;

  static const String apiVersion = 'v1';

  // API Endpoints
  static const String campaignsEndpoint = '/campaigns';
  static const String contributionsEndpoint = '/contributions';
  static const String usersEndpoint = '/users';
  static const String qrEndpoint = '/qr';

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
📡 API Mode: ${useLocalhost ? 'Local Development' : 'Production (Appwrite Function)'}
🌐 Base URL: $baseUrl
🔗 Appwrite Endpoint: ${useLocalhost ? 'N/A (using local server)' : appwriteFunctionUrl}
''';
}
