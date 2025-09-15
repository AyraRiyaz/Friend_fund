import 'package:get/get.dart';
import '../services/http_api_service.dart';
import '../services/cache_service.dart';
import '../models/campaign.dart';
import 'auth_controller.dart';

class CampaignController extends GetxController {
  static CampaignController get instance => Get.find();

  // Get HTTP API service instance
  HttpApiService get _httpApiService => Get.find<HttpApiService>();

  // Observables
  final RxList<Campaign> _campaigns = <Campaign>[].obs;
  final RxList<Campaign> _myCampaigns = <Campaign>[].obs;
  final Rx<Campaign?> _selectedCampaign = Rx<Campaign?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Campaign> get campaigns => _campaigns;
  List<Campaign> get myCampaigns => _myCampaigns;
  Campaign? get selectedCampaign => _selectedCampaign.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadCampaigns();
  }

  // Load all campaigns with caching
  Future<void> loadCampaigns() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      print('Loading campaigns from HTTP API...');

      // Fetch from API
      final campaigns = await _httpApiService.getAllCampaigns();
      _campaigns.assignAll(campaigns);

      // Cache the results
      await CacheService.cacheCampaigns(campaigns);
      print('Loaded ${campaigns.length} campaigns from API and cached');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load campaigns: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Load user's campaigns
  Future<void> loadMyCampaigns() async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final campaigns = await _httpApiService.getAllCampaigns(
        creatorId: authController
            .appwriteUser!
            .$id, // This will be mapped to hostId in the service
      );
      _myCampaigns.assignAll(campaigns);
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load your campaigns: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Get campaign details
  Future<void> getCampaignDetails(String campaignId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final campaign = await _httpApiService.getCampaign(campaignId);
      _selectedCampaign.value = campaign;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load campaign details: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Create new campaign
  Future<bool> createCampaign({
    required String title,
    required String description,
    required String purpose,
    required double targetAmount,
    DateTime? dueDate,
  }) async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) {
      Get.snackbar(
        'Authentication Required',
        'Please login to create a campaign',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final campaignData = {
        'hostId': authController.appwriteUser!.$id, // Backend expects 'hostId'
        'title': title,
        'description': description,
        'purpose': purpose,
        'targetAmount': targetAmount,
        'dueDate': dueDate?.toIso8601String(),
      };

      final campaign = await _httpApiService.createCampaign(
        campaignData,
        userId: authController.appwriteUser!.$id,
      );

      // Add to campaigns list
      _campaigns.insert(0, campaign);
      _myCampaigns.insert(0, campaign);

      // Invalidate cache since we have new data
      await CacheService.clearCampaignsCache();

      Get.snackbar(
        'Success',
        'Campaign created successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to create campaign: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update campaign
  Future<bool> updateCampaign({
    required String campaignId,
    String? title,
    String? description,
    String? status,
    double? targetAmount,
  }) async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final updateData = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (targetAmount != null) 'targetAmount': targetAmount,
      };

      final updatedCampaign = await _httpApiService.updateCampaign(
        campaignId,
        updateData,
        userId: authController.appwriteUser!.$id,
      );

      // Update in lists
      final campaignIndex = _campaigns.indexWhere((c) => c.id == campaignId);
      if (campaignIndex != -1) {
        _campaigns[campaignIndex] = updatedCampaign;
      }

      final myCampaignIndex = _myCampaigns.indexWhere(
        (c) => c.id == campaignId,
      );
      if (myCampaignIndex != -1) {
        _myCampaigns[myCampaignIndex] = updatedCampaign;
      }

      if (_selectedCampaign.value?.id == campaignId) {
        _selectedCampaign.value = updatedCampaign;
      }

      Get.snackbar(
        'Success',
        'Campaign updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update campaign: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete campaign
  Future<bool> deleteCampaign(String campaignId) async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _httpApiService.deleteCampaign(
        campaignId,
        userId: authController.appwriteUser!.$id,
      );

      // Remove from lists
      _campaigns.removeWhere((c) => c.id == campaignId);
      _myCampaigns.removeWhere((c) => c.id == campaignId);

      if (_selectedCampaign.value?.id == campaignId) {
        _selectedCampaign.value = null;
      }

      Get.snackbar(
        'Success',
        'Campaign deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to delete campaign: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Generate QR code for campaign
  Future<String?> generateQRCode(String campaignId) async {
    try {
      _isLoading.value = true;
      final qrData = await _httpApiService.generateQRCode(campaignId);
      return qrData['qrCode'] as String?;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate QR code: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Search campaigns
  List<Campaign> searchCampaigns(String query) {
    if (query.isEmpty) return _campaigns;

    return _campaigns
        .where(
          (campaign) =>
              campaign.title.toLowerCase().contains(query.toLowerCase()) ||
              campaign.description.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              campaign.purpose.toLowerCase().contains(query.toLowerCase()) ||
              campaign.hostName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Filter campaigns by purpose
  List<Campaign> filterByPurpose(String purpose) {
    if (purpose.isEmpty || purpose == 'All') return _campaigns;

    return _campaigns
        .where(
          (campaign) => campaign.purpose.toLowerCase() == purpose.toLowerCase(),
        )
        .toList();
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Refresh campaigns
  @override
  Future<void> refresh() async {
    await loadCampaigns();
    await loadMyCampaigns();
  }
}
