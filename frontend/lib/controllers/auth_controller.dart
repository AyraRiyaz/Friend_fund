import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as appwrite;
import '../services/appwrite_auth_service.dart';
import '../services/auth_token_service.dart';
import '../models/user.dart' as app_user;

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // Observables
  final Rx<AuthStatus> _authStatus = AuthStatus.unknown.obs;
  final Rx<appwrite.User?> _appwriteUser = Rx<appwrite.User?>(null);
  final Rx<app_user.User?> _userProfile = Rx<app_user.User?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  AuthStatus get authStatus => _authStatus.value;
  appwrite.User? get appwriteUser => _appwriteUser.value;
  app_user.User? get userProfile => _userProfile.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _authStatus.value == AuthStatus.authenticated;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  // Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final user = await AppwriteService.getCurrentUser();
      if (user != null) {
        _appwriteUser.value = user;
        await _loadUserProfile(user.$id);
        _authStatus.value = AuthStatus.authenticated;
      } else {
        _authStatus.value = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _authStatus.value = AuthStatus.unauthenticated;
    } finally {
      _isLoading.value = false;
    }
  }

  // Load user profile from preferences
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profile = await AppwriteService.getCurrentUserProfile();
      _userProfile.value = profile;
    } catch (e) {
      // If profile doesn't exist in preferences, we can create a basic one
      if (_appwriteUser.value != null) {
        try {
          final profile = await AppwriteService.createUserProfile(
            userId: userId,
            // UPI ID can be added later by the user
          );
          _userProfile.value = profile;
        } catch (createError) {
          // Handle profile creation error silently
        }
      }
    }
  }

  // Register with email and password
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? upiId,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Validate input fields
      if (email.isEmpty ||
          password.isEmpty ||
          name.isEmpty ||
          phoneNumber.isEmpty) {
        throw Exception('All required fields must be filled');
      }

      // Basic email validation
      if (!GetUtils.isEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      // Basic phone number validation (remove any spaces/special chars)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanPhoneNumber.length < 10) {
        throw Exception(
          'Please enter a valid phone number (minimum 10 digits)',
        );
      }

      // Check if user is already authenticated and logout first
      if (_authStatus.value == AuthStatus.authenticated) {
        try {
          await AppwriteService.logout();
          _authStatus.value = AuthStatus.unauthenticated;
          _appwriteUser.value = null;
          _userProfile.value = null;
        } catch (e) {
          // Handle logout error silently
        }
      }

      // Create account in Appwrite Auth
      final user = await AppwriteService.createAccount(
        email: email,
        password: password,
        name: name,
        phoneNumber: cleanPhoneNumber,
      );

      // If UPI ID is provided, store it in preferences now
      if (upiId != null && upiId.isNotEmpty) {
        try {
          // Create temporary session to store UPI ID
          await AppwriteService.createEmailSession(
            email: email,
            password: password,
          );

          // Store UPI ID in preferences
          await AppwriteService.createUserProfile(
            userId: user.$id,
            upiId: upiId,
          );

          // Logout after storing UPI ID (since we want manual login flow)
          await AppwriteService.logout();
        } catch (upiError) {
          // Continue without failing the registration
        }
      }

      // Don't set authentication status - user needs to login manually
      Get.snackbar(
        'Success',
        'Account created successfully! Please login with your credentials.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Registration Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Login with email and password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Create session in Appwrite
      final session = await AppwriteService.createEmailSession(
        email: email,
        password: password,
      );

      // Get user data
      final user = await AppwriteService.getCurrentUser();
      _appwriteUser.value = user;

      // Store authentication token
      await AuthTokenService.storeToken(session.$id, user!.$id);

      // Load user profile
      await _loadUserProfile(user.$id);

      _authStatus.value = AuthStatus.authenticated;

      Get.snackbar(
        'Success',
        'Logged in successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Phone Authentication
  Future<bool> sendPhoneOTP(String phoneNumber) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await AppwriteService.createPhoneSession(phoneNumber: phoneNumber);

      Get.snackbar(
        'OTP Sent',
        'Verification code sent to $phoneNumber',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'OTP Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> verifyPhoneOTP({
    required String userId,
    required String otp,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await AppwriteService.updatePhoneSession(userId: userId, secret: otp);

      final user = await AppwriteService.getCurrentUser();
      _appwriteUser.value = user;
      await _loadUserProfile(user!.$id);
      _authStatus.value = AuthStatus.authenticated;

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Verification Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? upiId,
    String? profileImage,
  }) async {
    if (_appwriteUser.value == null) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final updatedProfile = await AppwriteService.updateUserProfile(
        userId: _appwriteUser.value!.$id,
        name: name,
        phoneNumber: phoneNumber,
        upiId: upiId,
        profileImage: profileImage,
      );

      _userProfile.value = updatedProfile;

      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Update Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Password Recovery
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await AppwriteService.createRecovery(
        email: email,
        url: 'https://friendfund.pro26.in/reset-password', // Your reset URL
      );

      Get.snackbar(
        'Recovery Email Sent',
        'Check your email for password reset instructions',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Recovery Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading.value = true;
      await AppwriteService.logout();
      // Clear stored authentication data
      await AuthTokenService.clearAuth();
    } catch (e) {
      // Handle logout error silently
    } finally {
      _appwriteUser.value = null;
      _userProfile.value = null;
      _authStatus.value = AuthStatus.unauthenticated;
      _isLoading.value = false;
      _errorMessage.value = '';
    }
  }

  // Logout from all devices
  Future<void> logoutFromAllDevices() async {
    try {
      _isLoading.value = true;
      await AppwriteService.logoutFromAllDevices();
      // Clear stored authentication data
      await AuthTokenService.clearAuth();
    } catch (e) {
      // Handle logout error silently
    } finally {
      _appwriteUser.value = null;
      _userProfile.value = null;
      _authStatus.value = AuthStatus.unauthenticated;
      _isLoading.value = false;
      _errorMessage.value = '';
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }
}
