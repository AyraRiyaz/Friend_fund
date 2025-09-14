import 'package:get/get.dart';
import 'package:appwrite/models.dart' as appwrite;
import '../services/appwrite_auth_service.dart';
import '../services/api_service.dart';
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
      print('Auth check error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Load user profile from backend
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profile = await ApiService.getUserProfile(userId);
      _userProfile.value = profile;
    } catch (e) {
      print('Failed to load user profile: $e');
      // Profile might not exist yet, that's okay
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

      // Create account in Appwrite Auth
      final user = await AppwriteService.createAccount(
        email: email,
        password: password,
        name: name,
      );

      // Automatically login after registration
      await AppwriteService.createEmailSession(
        email: email,
        password: password,
      );

      // Create user profile in backend
      final profile = await ApiService.createUserProfile(
        userId: user.$id,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        upiId: upiId,
      );

      _appwriteUser.value = user;
      _userProfile.value = profile;
      _authStatus.value = AuthStatus.authenticated;

      Get.snackbar(
        'Success',
        'Account created successfully!',
        snackPosition: SnackPosition.BOTTOM,
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
      await AppwriteService.createEmailSession(
        email: email,
        password: password,
      );

      // Get user data
      final user = await AppwriteService.getCurrentUser();
      _appwriteUser.value = user;

      // Load user profile
      await _loadUserProfile(user!.$id);

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

      final updatedProfile = await ApiService.updateUserProfile(
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
    } catch (e) {
      print('Logout error: $e');
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
    } catch (e) {
      print('Logout from all devices error: $e');
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
