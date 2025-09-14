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
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
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

  // User Profile Management
  static Future<app_user.User> createUserProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
    String? upiId,
    String? profileImage,
  }) async {
    try {
      print('Creating user profile with data:');
      print('UserId: $userId');
      print('Name: $name');
      print('Phone: $phoneNumber');
      print('Email: $email');
      print('UPI: $upiId');
      print('Database ID: ${AppwriteConfig.databaseId}');
      print('Collection ID: ${AppwriteConfig.usersCollectionId}');

      final document = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'name': name,
          'mobileNumber': phoneNumber, // Fixed: using mobileNumber to match database schema
          'email': email,
          'upiId': upiId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      print('User profile document created successfully: ${document.data}');
      return app_user.User.fromJson(document.data);
    } catch (e) {
      print('Error creating user profile: $e');
      throw _handleAppwriteException(e);
    }
  }

  static Future<app_user.User> getUserProfile(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
      );

      return app_user.User.fromJson(document.data);
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
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['mobileNumber'] = phoneNumber; // Fixed: using mobileNumber
      if (upiId != null) updateData['upiId'] = upiId;
      if (profileImage != null) updateData['profileImage'] = profileImage;
      updateData['updatedAt'] = DateTime.now().toIso8601String(); // Always update timestamp

      final document = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: updateData,
      );

      return app_user.User.fromJson(document.data);
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
