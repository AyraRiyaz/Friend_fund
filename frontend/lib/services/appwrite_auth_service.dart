import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../config/appwrite_config.dart';
import '../models/user.dart' as app_user;

class AppwriteService {
  static late Client _client;
  static late Account _account;
  static late Databases _databases;
  static late Storage _storage;

  static void initialize() {
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    // Set platform for web deployment
    if (kIsWeb) {
      // Check if running on deployed domain
      final currentHost = Uri.base.host;
      if (currentHost == 'friendfund-pro26.netlify.app') {
        _client.addHeader('X-Appwrite-Origin', AppwriteConfig.webPlatform);
      } else if (currentHost == 'localhost') {
        _client.addHeader('X-Appwrite-Origin',
            '${AppwriteConfig.localPlatform}:${Uri.base.port}');
      }
    }

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
  }

  // Getters
  static Client get client => _client;
  static Account get account => _account;
  static Databases get databases => _databases;
  static Storage get storage => _storage;

  // Authentication Methods
  static Future<User> createAccount({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Store phone number in the actual phone field of Appwrite Auth
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        try {
          // Create a temporary session to get permissions for phone update
          await _account.createEmailPasswordSession(
            email: email,
            password: password,
          );

          // Update phone number in the auth account phone field
          await _account.updatePhone(phone: phoneNumber, password: password);

          // Logout after updating phone (since we want manual login flow)
          await _account.deleteSession(sessionId: 'current');
        } catch (phoneError) {
          // Continue without failing the registration
        }
      }

      return user;
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  static Future<Session> createEmailSession({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return user;
    } catch (e) {
      // Return null if user is not authenticated
      return null;
    }
  }

  static Future<Session?> getCurrentSession() async {
    try {
      return await _account.getSession(sessionId: 'current');
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  static Future<void> logoutFromAllDevices() async {
    try {
      await _account.deleteSessions();
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  // Phone Authentication
  static Future<Token> createPhoneSession({required String phoneNumber}) async {
    try {
      final token = await _account.createPhoneToken(
        userId: ID.unique(),
        phone: phoneNumber,
      );
      return token;
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  static Future<Session> updatePhoneSession({
    required String userId,
    required String secret,
  }) async {
    try {
      final session = await _account.updatePhoneSession(
        userId: userId,
        secret: secret,
      );
      return session;
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  // Password Recovery
  static Future<Token> createRecovery({
    required String email,
    required String url,
  }) async {
    try {
      final token = await _account.createRecovery(email: email, url: url);
      return token;
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  // User Profile Management using Auth Preferences (for UPI ID only)
  static Future<app_user.User> createUserProfile({
    required String userId,
    String? upiId,
    String? profileImage,
  }) async {
    try {
      // Store only UPI ID and profile image in preferences
      // (phone is in auth phone field, name and email in auth account)
      await _account.updatePrefs(
        prefs: {
          'upiId': upiId ?? '',
          'profileImage': profileImage ?? '',
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      // Return user object constructed from auth data and preferences
      final user = await getCurrentUserProfile();
      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to retrieve user after profile creation');
      }
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  static Future<app_user.User?> getCurrentUserProfile() async {
    try {
      final account = await _account.get();
      final prefs = account.prefs.data;

      return app_user.User(
        id: account.$id,
        name: account.name,
        email: account.email,
        phoneNumber: account.phone, // Get phone from auth phone field
        upiId: prefs['upiId'],
        profileImage: prefs['profileImage'],
        joinedAt: prefs['joinedAt'] != null || prefs['registeredAt'] != null
            ? DateTime.parse(prefs['joinedAt'] ?? prefs['registeredAt'])
            : DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<app_user.User> getUserProfile(String userId) async {
    try {
      // For current user, we can get from account
      final currentAccount = await _account.get();
      if (currentAccount.$id == userId) {
        final user = await getCurrentUserProfile();
        if (user != null) {
          return user;
        } else {
          throw Exception('User not found');
        }
      }

      // For other users, we'll need to use a different approach
      // since we can't access other users' preferences directly
      throw Exception(
        'Cannot access other users\' profiles without users collection',
      );
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  static Future<app_user.User> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? upiId,
    String? profileImage,
    String? password, // Password might be needed for phone/email updates
  }) async {
    try {
      // Update name in account if provided
      if (name != null && name.isNotEmpty) {
        await _account.updateName(name: name);
      }

      // Update email if provided
      if (email != null && email.isNotEmpty && password != null) {
        try {
          await _account.updateEmail(email: email, password: password);
        } catch (emailError) {
          // Note: Email update might fail if password is incorrect or email already exists
          rethrow;
        }
      }

      // Update phone number in auth phone field if provided
      if (phoneNumber != null && phoneNumber.isNotEmpty && password != null) {
        try {
          await _account.updatePhone(phone: phoneNumber, password: password);
        } catch (phoneError) {
          // Note: Phone update might fail if password is incorrect or other validation issues
          rethrow;
        }
      }

      // Get current preferences
      final currentAccount = await _account.get();
      final currentPrefs = Map<String, dynamic>.from(currentAccount.prefs.data);

      // Update preferences (excluding phone since it's now in auth phone field)
      final updatedPrefs = <String, dynamic>{
        ...currentPrefs,
        if (upiId != null) 'upiId': upiId,
        if (profileImage != null) 'profileImage': profileImage,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _account.updatePrefs(prefs: updatedPrefs);

      final user = await getCurrentUserProfile();
      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to get updated user');
      }
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  // Update Password
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _account.updatePassword(
        password: newPassword,
        oldPassword: currentPassword,
      );
    } catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  // Error Handling
  static String _handleAppwriteException(dynamic e) {
    if (e is AppwriteException) {
      // Print debug information for troubleshooting
      print(
          'Appwrite Exception - Code: ${e.code}, Message: ${e.message}, Type: ${e.type}');

      switch (e.code) {
        case 401:
          return 'Invalid credentials. Please check your email and password.';
        case 409:
          return 'An account with this email already exists.';
        case 429:
          return 'Too many requests. Please try again later.';
        case 400:
          return e.message ?? 'Invalid request. Please check your input.';
        case 404:
          return 'Resource not found. Please check your configuration.';
        case 500:
          return 'Server error. Please try again later.';
        case 503:
          return 'Service temporarily unavailable. Please try again later.';
        default:
          // Return more detailed error for debugging in development
          if (kDebugMode) {
            return '${e.message} (Code: ${e.code}, Type: ${e.type})';
          }
          return e.message ?? 'An error occurred. Please try again.';
      }
    }

    // Handle network and other errors
    if (e.toString().contains('Failed host lookup') ||
        e.toString().contains('Connection refused') ||
        e.toString().contains('Network is unreachable')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'An unexpected error occurred: $e';
  }
}
