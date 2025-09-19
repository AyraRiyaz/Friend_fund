import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';
import '../models/user.dart' as app_user;
import 'http_api_service.dart';

class AppwriteService {
  static Client? _client;
  static Databases? _databases;
  static Account? _account;
  static Storage? _storage;
  static final HttpApiService _httpApiService = HttpApiService();

  static Client get client {
    _client ??= Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    return _client!;
  }

  static Databases get databases {
    _databases ??= Databases(client);
    return _databases!;
  }

  static Account get account {
    _account ??= Account(client);
    return _account!;
  }

  static Storage get storage {
    _storage ??= Storage(client);
    return _storage!;
  }

  // Initialize the service
  static void initialize() {
    client;
    databases;
    account;
    storage;
  }

  // Get user profile from Appwrite Users API
  static Future<app_user.User> getUserProfile(String userId) async {
    try {
      final user = await account.get();
      final prefs = user.prefs;

      return app_user.User(
        id: user.$id,
        name: user.name,
        email: user.email,
        phoneNumber: prefs.data['phoneNumber'] ?? '',
        upiId: prefs.data['upiId'] ?? '',
        profileImage: prefs.data['profileImage'] ?? '',
        joinedAt: DateTime.parse(user.$createdAt),
      );
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Campaign contribution methods
  Future<Map<String, dynamic>> getCampaignForContribution(
    String campaignId,
  ) async {
    return await _httpApiService.getCampaignForContribution(campaignId);
  }

  Future<Map<String, dynamic>> createContribution(
    Map<String, dynamic> contributionData,
  ) async {
    return await _httpApiService.createContributionV2(
      campaignId: contributionData['campaignId'],
      contributorId: contributionData['contributorId'] ?? 'anonymous',
      contributorName: contributionData['contributorName'],
      amount: contributionData['amount'],
      utr: contributionData['utrNumber'],
      type: contributionData['type'] ?? 'gift',
      additionalData: {
        'paymentScreenshotUrl': contributionData['paymentScreenshotUrl'],
        'paymentStatus': contributionData['paymentStatus'],
      },
    );
  }

  Future<Map<String, dynamic>> uploadFile(dynamic file) async {
    return await _httpApiService.uploadFile(file);
  }

  Future<Map<String, dynamic>> generatePaymentQR({
    required String campaignId,
    required String upiId,
    required double amount,
  }) async {
    return await _httpApiService.generatePaymentQR(
      campaignId: campaignId,
      upiId: upiId,
      amount: amount,
    );
  }
}
