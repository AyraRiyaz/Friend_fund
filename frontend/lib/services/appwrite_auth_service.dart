import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
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
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(status: true); // Only for development

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
  }) async {
    try {
      print('Creating Appwrite Auth account for: $email with name: $name');

      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      print('Appwrite Auth account created successfully: ${user.$id}');
      return user;
    } catch (e) {
      print('Error creating Appwrite Auth account: $e');
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

  // User Profile Management using Auth Labels and Preferences
  static Future<app_user.User> createUserProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
    String? upiId,
    String? profileImage,
  }) async {
    try {
      print('Creating user profile using Auth preferences...');
      print('UserId: $userId');
      print('Name: $name');
      print('Phone: $phoneNumber');
      print('Email: $email');
      print('UPI: $upiId');

      // Validate required fields
      if (userId.isEmpty ||
          name.isEmpty ||
          phoneNumber.isEmpty ||
          email.isEmpty) {
        throw Exception('Missing required fields for user profile creation');
      }

      // Store user data in preferences
      await _account.updatePrefs(
        prefs: {
          'phoneNumber': phoneNumber,
          'upiId': upiId ?? '',
          'profileImage': profileImage ?? '',
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      print('User profile created successfully using preferences');

      // Return user object constructed from auth data and preferences
      final user = await getCurrentUserProfile();
      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to retrieve user after profile creation');
      }
    } catch (e) {
      print('Error creating user profile: $e');
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
        phoneNumber: prefs['phoneNumber'] ?? '',
        upiId: prefs['upiId'],
        profileImage: prefs['profileImage'],
        joinedAt: prefs['joinedAt'] != null
            ? DateTime.parse(prefs['joinedAt'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Error getting current user: $e');
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
    String? upiId,
    String? profileImage,
  }) async {
    try {
      // Update name in account if provided
      if (name != null && name.isNotEmpty) {
        await _account.updateName(name: name);
      }

      // Get current preferences
      final currentAccount = await _account.get();
      final currentPrefs = Map<String, dynamic>.from(currentAccount.prefs.data);

      // Update preferences
      final updatedPrefs = <String, dynamic>{
        ...currentPrefs,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
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

  // Error Handling
  static String _handleAppwriteException(dynamic e) {
    print('Appwrite Exception: $e'); // Add logging
    if (e is AppwriteException) {
      print('Appwrite Exception Code: ${e.code}, Message: ${e.message}');
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
        default:
          return e.message ?? 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred: $e';
  }
}
