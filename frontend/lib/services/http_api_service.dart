import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/campaign.dart';
import '../models/user.dart' as app_user;

/// HTTP API service for FriendFund backend integration
/// Handles all REST API calls to the Node.js backend server
class HttpApiService {
  static final HttpApiService _instance = HttpApiService._internal();
  factory HttpApiService() => _instance;
  HttpApiService._internal();

  final http.Client _client = http.Client();

  /// Get headers for HTTP requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get headers with user authentication
  Map<String, String> _headersWithAuth(String? userId) => {
    ..._headers,
    if (userId != null) 'x-user-id': userId,
  };

  /// Handle HTTP response and extract data
  Map<String, dynamic> _handleResponse(http.Response response) {
    AppConfig.debugPrint('Response Status: ${response.statusCode}');
    AppConfig.debugPrint('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'API request failed');
        }
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      } catch (e) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    }
  }

  // Campaign Operations

  /// Get all campaigns with optional filters
  Future<List<Campaign>> getAllCampaigns({
    String? creatorId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.campaignsEndpoint}',
      );

      final queryParams = <String, String>{};
      if (creatorId != null && creatorId.isNotEmpty)
        queryParams['hostId'] =
            creatorId; // Backend expects 'hostId' not 'creatorId'
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final finalUri = queryParams.isEmpty
          ? uri
          : uri.replace(queryParameters: queryParams);

      AppConfig.debugPrint('GET Campaigns: $finalUri');

      final response = await _client
          .get(finalUri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] is List) {
        final campaignsData = data['data'] as List;
        return campaignsData.map((json) => Campaign.fromJson(json)).toList();
      } else {
        throw Exception('Invalid campaigns data format');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to connect to server. Please try again later.');
    }
  }

  /// Get a specific campaign by ID with contributions
  Future<Campaign> getCampaign(String campaignId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.campaignsEndpoint}/$campaignId',
      );

      AppConfig.debugPrint('GET Campaign: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return Campaign.fromJson(data['data']);
      } else {
        throw Exception('Campaign not found');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to load campaign. Please try again later.');
    }
  }

  /// Get campaign details for contribution form (public access)
  Future<Map<String, dynamic>> getCampaignForContribution(
    String campaignId,
  ) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.campaignsEndpoint}/$campaignId/contribute',
      );

      AppConfig.debugPrint('GET Campaign for Contribution: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data;
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to load campaign. Please try again later.');
    }
  }

  /// Create a new campaign
  Future<Campaign> createCampaign(
    Map<String, dynamic> campaignData, {
    String? userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.campaignsEndpoint}',
      );

      AppConfig.debugPrint('POST Campaign: $uri');
      AppConfig.debugPrint('Campaign Data: ${jsonEncode(campaignData)}');

      final response = await _client
          .post(
            uri,
            headers: _headersWithAuth(userId),
            body: jsonEncode(campaignData),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return Campaign.fromJson(data['data']);
      } else {
        throw Exception('Failed to create campaign');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to create campaign. Please try again later.');
    }
  }

  /// Update an existing campaign
  Future<Campaign> updateCampaign(
    String campaignId,
    Map<String, dynamic> updateData, {
    String? userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.campaignsEndpoint}/$campaignId',
      );

      AppConfig.debugPrint('PATCH Campaign: $uri');
      AppConfig.debugPrint('Update Data: ${jsonEncode(updateData)}');

      final response = await _client
          .patch(
            uri,
            headers: _headersWithAuth(userId),
            body: jsonEncode(updateData),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return Campaign.fromJson(data['data']);
      } else {
        throw Exception('Failed to update campaign');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to update campaign. Please try again later.');
    }
  }

  /// Delete a campaign
  Future<void> deleteCampaign(String campaignId, {String? userId}) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.campaignsEndpoint}/$campaignId',
      );

      AppConfig.debugPrint('DELETE Campaign: $uri');

      final response = await _client
          .delete(uri, headers: _headersWithAuth(userId))
          .timeout(AppConfig.connectTimeout);

      _handleResponse(response);
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to delete campaign. Please try again later.');
    }
  }

  // Contribution Operations

  /// Get contributions for a specific campaign
  Future<List<Contribution>> getCampaignContributions(String campaignId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.contributionsEndpoint}/campaign/$campaignId',
      );

      AppConfig.debugPrint('GET Campaign Contributions: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] is List) {
        final contributionsData = data['data'] as List;
        return contributionsData
            .map((json) => Contribution.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid contributions data format');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to load contributions. Please try again later.');
    }
  }

  /// Get contributions for a specific user
  Future<List<Contribution>> getUserContributions(String userId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.contributionsEndpoint}/user/$userId',
      );

      AppConfig.debugPrint('GET User Contributions: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] is List) {
        final contributionsData = data['data'] as List;
        return contributionsData
            .map((json) => Contribution.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid contributions data format');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception(
        'Failed to load user contributions. Please try again later.',
      );
    }
  }

  /// Create a new contribution
  Future<Contribution> createContribution(
    Map<String, dynamic> contributionData, {
    String? userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.contributionsEndpoint}',
      );

      AppConfig.debugPrint('POST Contribution: $uri');
      AppConfig.debugPrint(
        'Contribution Data: ${jsonEncode(contributionData)}',
      );

      final response = await _client
          .post(
            uri,
            headers: _headersWithAuth(userId),
            body: jsonEncode(contributionData),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return Contribution.fromJson(data['data']);
      } else {
        throw Exception('Failed to create contribution');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to create contribution. Please try again later.');
    }
  }

  /// Mark a loan contribution as repaid
  Future<Contribution> markLoanRepaid({
    required String contributionId,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.contributionsEndpoint}/$contributionId',
      );

      AppConfig.debugPrint('PATCH Contribution (mark as repaid): $uri');

      final updateData = {
        'repaymentStatus': 'repaid', // Backend expects 'repaymentStatus'
        'repaidAt': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .patch(
            uri,
            headers: _headersWithAuth(userId),
            body: jsonEncode(updateData),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return Contribution.fromJson(data['data']);
      } else {
        throw Exception('Failed to mark loan as repaid');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to mark loan as repaid. Please try again later.');
    }
  }

  // Utility Operations

  /// Generate QR code for a campaign
  Future<Map<String, dynamic>> generateQRCode(String campaignId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.qrEndpoint}/$campaignId',
      );

      AppConfig.debugPrint('GET QR Code: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to generate QR code');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to generate QR code. Please try again later.');
    }
  }

  /// Generate UPI payment QR code for a campaign with amount
  Future<Map<String, dynamic>> generatePaymentQR({
    required String campaignId,
    required String upiId,
    required double amount,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.paymentQrEndpoint}/$campaignId',
      );

      final body = json.encode({'upiId': upiId, 'amount': amount});

      AppConfig.debugPrint('POST Payment QR: $uri');
      AppConfig.debugPrint('Payment QR Body: $body');

      final response = await _client
          .post(uri, headers: _headers, body: body)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to generate payment QR code');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception(
        'Failed to generate payment QR code. Please try again later.',
      );
    }
  }

  /// Get user information
  Future<app_user.User> getUser(String userId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.usersEndpoint}/$userId',
      );

      AppConfig.debugPrint('GET User: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);

      if (data['data'] != null) {
        return app_user.User.fromJson(data['data']);
      } else {
        throw Exception('User not found');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception(
        'Failed to load user information. Please try again later.',
      );
    }
  }

  /// Get platform summary statistics
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/summary');

      AppConfig.debugPrint('GET Summary: $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data['data'] ?? {};
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to load summary. Please try again later.');
    }
  }

  /// Get user dashboard with statistics
  Future<Map<String, dynamic>> getUserDashboard(String userId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.usersEndpoint}/$userId/dashboard',
      );

      AppConfig.debugPrint('GET User Dashboard: $uri');

      final response = await _client
          .get(uri, headers: _headersWithAuth(userId))
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data['data'] ?? {};
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to load dashboard. Please try again later.');
    }
  }

  /// Get user's overdue loans
  Future<List<dynamic>> getOverdueLoans(String userId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.usersEndpoint}/$userId/overdue-loans',
      );

      AppConfig.debugPrint('GET Overdue Loans: $uri');

      final response = await _client
          .get(uri, headers: _headersWithAuth(userId))
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data['data'] ?? [];
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to load overdue loans. Please try again later.');
    }
  }

  /// Mark loan as repaid (enhanced version)
  Future<Map<String, dynamic>> markLoanRepaidV2(
    String loanId,
    Map<String, dynamic> repaymentData,
    String userId,
  ) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/loans/$loanId/repaid');

      AppConfig.debugPrint('PATCH Mark Loan Repaid: $uri');
      AppConfig.debugPrint('Repayment Data: ${json.encode(repaymentData)}');

      final response = await _client
          .patch(
            uri,
            headers: _headersWithAuth(userId),
            body: json.encode(repaymentData),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data;
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to mark loan as repaid. Please try again later.');
    }
  }

  /// Enhanced contribution creation with better validation
  Future<Map<String, dynamic>> createContributionV2({
    required String campaignId,
    required String contributorId,
    required String contributorName,
    required double amount,
    required String utr,
    required String type,
    String? repaymentStatus,
    bool isAnonymous = false,
    DateTime? repaymentDueDate,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final contributionData = {
        'campaignId': campaignId,
        'contributorId': contributorId,
        'contributorName': isAnonymous ? 'Anonymous' : contributorName,
        'amount': amount.toString(), // Convert to string for backend
        'utr': utr,
        'type': type,
        'repaymentStatus':
            repaymentStatus ?? (type == 'loan' ? 'pending' : null),
        'isAnonymous': isAnonymous,
        'repaymentDueDate': repaymentDueDate?.toIso8601String(),
        ...?additionalData,
      };

      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.contributionsEndpoint}',
      );

      AppConfig.debugPrint('POST Enhanced Contribution: $uri');
      AppConfig.debugPrint(
        'Contribution Data: ${json.encode(contributionData)}',
      );

      final response = await _client
          .post(
            uri,
            headers: _headersWithAuth(contributorId),
            body: json.encode(contributionData),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data;
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to create contribution. Please try again later.');
    }
  }

  /// Upload a file (for payment screenshots)
  Future<Map<String, dynamic>> uploadFile(dynamic file) async {
    try {
      // For now, we'll return a placeholder response
      // In a real implementation, you would upload to a file storage service
      // like Appwrite Storage, AWS S3, or Cloudinary

      // This is a mock implementation - replace with actual file upload logic
      return {
        'success': true,
        'fileUrl': 'https://placeholder.com/payment-screenshot.jpg',
        'fileId': 'mock-file-id-${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Process payment screenshot with OCR
  Future<Map<String, dynamic>> processPaymentScreenshot({
    required String imageBase64,
    required double expectedAmount,
    required String contributorName,
    required String campaignId,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/payment/process-screenshot');

      AppConfig.debugPrint('POST Process Payment Screenshot: $uri');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode({
              'imageBase64': imageBase64,
              'expectedAmount': expectedAmount,
              'contributorName': contributorName,
              'campaignId': campaignId,
            }),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data;
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception(
        'Failed to process payment screenshot. Please try again later.',
      );
    }
  }

  /// Upload payment screenshot to storage
  Future<Map<String, dynamic>> uploadPaymentScreenshot({
    required String fileBase64,
    required String fileName,
    required String contributionId,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/payment/upload-screenshot');

      AppConfig.debugPrint('POST Upload Payment Screenshot: $uri');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode({
              'fileBase64': fileBase64,
              'fileName': fileName,
              'contributionId': contributionId,
            }),
          )
          .timeout(AppConfig.connectTimeout);

      final data = _handleResponse(response);
      return data;
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to upload screenshot. Please try again later.');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
