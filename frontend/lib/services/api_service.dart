import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/appwrite_config.dart';
import '../models/campaign.dart';
import '../models/user.dart' as app_user;
import 'auth_token_service.dart';

class ApiService {
  static const String baseUrl = AppwriteConfig.backendFunctionUrl;

  static Future<Map<String, String>> _getHeaders({String? userId}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authentication headers if user is logged in
    try {
      final token = await AuthTokenService.getToken();
      final currentUserId = userId ?? AuthTokenService.getUserId();

      if (token != null && currentUserId != null) {
        headers['x-appwrite-user-id'] = currentUserId;
        headers['x-appwrite-user-jwt'] = token;
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting auth headers: $e');
    }

    return headers;
  }

  static Future<Map<String, dynamic>> _makeRequest({
    required String path,
    required String method,
    String? userId,
    Map<String, dynamic>? body,
  }) async {
    try {
      final requestBody = {
        'path': path,
        'method': method,
        if (body != null) 'bodyJson': body,
      };

      final headers = await _getHeaders(userId: userId);
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData;
        } else {
          throw Exception(responseData['message'] ?? 'API request failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Health Check
  static Future<bool> healthCheck() async {
    try {
      final result = await _makeRequest(path: '/health', method: 'GET');
      return result['success'] == true;
    } catch (e) {
      return false;
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
    final result = await _makeRequest(
      path: '/users/profile',
      method: 'POST',
      userId: userId,
      body: {
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        if (upiId != null) 'upiId': upiId,
        if (profileImage != null) 'profileImage': profileImage,
      },
    );

    return app_user.User.fromJson(result['data']);
  }

  static Future<app_user.User> getUserProfile(String userId) async {
    final result = await _makeRequest(
      path: '/users/$userId',
      method: 'GET',
      userId: userId,
    );

    return app_user.User.fromJson(result['data']);
  }

  static Future<app_user.User> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? upiId,
    String? profileImage,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (upiId != null) body['upiId'] = upiId;
    if (profileImage != null) body['profileImage'] = profileImage;

    final result = await _makeRequest(
      path: '/users/$userId',
      method: 'PUT',
      userId: userId,
      body: body,
    );

    return app_user.User.fromJson(result['data']);
  }

  // Campaign Management
  static Future<List<Campaign>> getCampaigns() async {
    final result = await _makeRequest(path: '/campaigns', method: 'GET');

    final campaignsData = result['data'] as List;
    return campaignsData.map((json) => Campaign.fromJson(json)).toList();
  }

  static Future<Campaign> getCampaign(String campaignId) async {
    final result = await _makeRequest(
      path: '/campaigns/$campaignId',
      method: 'GET',
    );

    return Campaign.fromJson(result['data']);
  }

  static Future<List<Campaign>> getUserCampaigns(String userId) async {
    final result = await _makeRequest(
      path: '/campaigns/user',
      method: 'GET',
      userId: userId,
    );

    final campaignsData = result['data'] as List;
    return campaignsData.map((json) => Campaign.fromJson(json)).toList();
  }

  static Future<Campaign> createCampaign({
    required String userId,
    required String title,
    required String description,
    required String purpose,
    required double targetAmount,
    DateTime? dueDate,
  }) async {
    final result = await _makeRequest(
      path: '/campaigns',
      method: 'POST',
      userId: userId,
      body: {
        'title': title,
        'description': description,
        'purpose': purpose,
        'targetAmount': targetAmount,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
    );

    return Campaign.fromJson(result['data']);
  }

  static Future<Campaign> updateCampaign({
    required String campaignId,
    required String userId,
    String? title,
    String? description,
    String? status,
    double? targetAmount,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;
    if (targetAmount != null) body['targetAmount'] = targetAmount;

    final result = await _makeRequest(
      path: '/campaigns/$campaignId',
      method: 'PUT',
      userId: userId,
      body: body,
    );

    return Campaign.fromJson(result['data']);
  }

  static Future<void> deleteCampaign({
    required String campaignId,
    required String userId,
  }) async {
    await _makeRequest(
      path: '/campaigns/$campaignId',
      method: 'DELETE',
      userId: userId,
    );
  }

  // Contribution Management
  static Future<List<Contribution>> getCampaignContributions(
    String campaignId,
  ) async {
    final result = await _makeRequest(
      path: '/contributions/campaign/$campaignId',
      method: 'GET',
    );

    final contributionsData = result['data'] as List;
    return contributionsData
        .map((json) => Contribution.fromJson(json))
        .toList();
  }

  static Future<List<Contribution>> getUserContributions(String userId) async {
    final result = await _makeRequest(
      path: '/contributions/user/$userId',
      method: 'GET',
      userId: userId,
    );

    final contributionsData = result['data'] as List;
    return contributionsData
        .map((json) => Contribution.fromJson(json))
        .toList();
  }

  static Future<Contribution> createContribution({
    required String userId,
    required String campaignId,
    required double amount,
    required String utrNumber,
    required String type,
    bool isAnonymous = false,
    String? paymentScreenshotUrl,
    DateTime? repaymentDueDate,
  }) async {
    final result = await _makeRequest(
      path: '/contributions',
      method: 'POST',
      userId: userId,
      body: {
        'campaignId': campaignId,
        'amount': amount,
        'utrNumber': utrNumber,
        'type': type,
        'isAnonymous': isAnonymous,
        if (paymentScreenshotUrl != null)
          'paymentScreenshotUrl': paymentScreenshotUrl,
        if (repaymentDueDate != null)
          'repaymentDueDate': repaymentDueDate.toIso8601String(),
      },
    );

    return Contribution.fromJson(result['data']);
  }

  static Future<Contribution> markLoanRepaid({
    required String contributionId,
    required String userId,
  }) async {
    final result = await _makeRequest(
      path: '/contributions/repaid/$contributionId',
      method: 'PATCH',
      userId: userId,
    );

    return Contribution.fromJson(result['data']);
  }

  // QR Code Generation
  static Future<String> generateQRCode(String campaignId) async {
    final result = await _makeRequest(path: '/qr/$campaignId', method: 'GET');

    return result['data']['qrCodeUrl'];
  }

  // OCR Processing
  static Future<Map<String, dynamic>> processOCR({
    required String userId,
    required String imageData,
  }) async {
    final result = await _makeRequest(
      path: '/ocr/process',
      method: 'POST',
      userId: userId,
      body: {'imageData': imageData},
    );

    return result['data'];
  }

  // Notifications
  static Future<List<Map<String, dynamic>>> getOverdueLoans(
    String userId,
  ) async {
    final result = await _makeRequest(
      path: '/notifications/overdue',
      method: 'GET',
      userId: userId,
    );

    return List<Map<String, dynamic>>.from(result['data']);
  }

  static Future<void> sendLoanReminder({
    required String userId,
    required String contributionId,
  }) async {
    await _makeRequest(
      path: '/notifications/reminder',
      method: 'POST',
      userId: userId,
      body: {'contributionId': contributionId},
    );
  }
}
