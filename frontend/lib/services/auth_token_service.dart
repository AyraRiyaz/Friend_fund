import 'package:get_storage/get_storage.dart';
import 'appwrite_auth_service.dart';

class AuthTokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static final GetStorage _storage = GetStorage();

  /// Get the current JWT token
  static Future<String?> getToken() async {
    try {
      // Try to get fresh session token from Appwrite
      final session = await AppwriteService.getCurrentSession();
      if (session != null) {
        // Store the token for offline access
        await _storage.write(_tokenKey, session.$id);
        return session.$id;
      }
    } catch (e) {
      // If no active session, try to get cached token
      return _storage.read(_tokenKey);
    }
    return null;
  }

  /// Store the authentication token
  static Future<void> storeToken(String token, String userId) async {
    await _storage.write(_tokenKey, token);
    await _storage.write(_userIdKey, userId);
  }

  /// Get the current user ID
  static String? getUserId() {
    return _storage.read(_userIdKey);
  }

  /// Clear stored authentication data
  static Future<void> clearAuth() async {
    await _storage.remove(_tokenKey);
    await _storage.remove(_userIdKey);
  }

  /// Check if user has valid authentication
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    final userId = getUserId();
    return token != null && userId != null;
  }
}
