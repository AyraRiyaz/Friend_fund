import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../services/http_api_service.dart';
import '../models/campaign.dart';
import 'auth_controller.dart';

class ContributionController extends GetxController {
  static ContributionController get instance => Get.find();

  // Get HTTP API service instance
  HttpApiService get _httpApiService => Get.find<HttpApiService>();

  // Observables
  final RxList<Contribution> _contributions = <Contribution>[].obs;
  final RxList<Contribution> _userContributions = <Contribution>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Contribution> get contributions => _contributions;
  List<Contribution> get userContributions => _userContributions;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadUserContributions();
  }

  /// Create a new contribution
  Future<Contribution?> createContribution(
    Map<String, dynamic> contributionData,
  ) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final authController = AuthController.instance;
      final userId = authController.isAuthenticated
          ? authController.appwriteUser?.$id
          : null;

      developer.log(
        'Creating contribution with data: $contributionData',
        name: 'ContributionController',
      );

      final contribution = await _httpApiService.createContribution(
        contributionData,
        userId: userId,
      );

      // Add to local lists
      _contributions.add(contribution);
      if (userId != null) {
        _userContributions.add(contribution);
      }

      // Trigger UI update for GetBuilder widgets
      update();

      Get.snackbar(
        'Success',
        'Contribution created successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return contribution;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to create contribution: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load user's contributions
  Future<void> loadUserContributions() async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final contributions = await _httpApiService.getUserContributions(
        authController.appwriteUser!.$id,
      );
      _userContributions.assignAll(contributions);

      developer.log(
        'Loaded ${contributions.length} user contributions',
        name: 'ContributionController',
      );
      // Trigger UI update for GetBuilder widgets
      update();
    } catch (e) {
      _errorMessage.value = e.toString();
      developer.log(
        'Error loading user contributions: $e',
        name: 'ContributionController',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load loans that the user needs to repay (loans received on their campaigns)
  Future<List<Contribution>> loadLoansToRepay() async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) {
      developer.log(
        'User not authenticated for loading loans to repay',
        name: 'ContributionController',
      );
      return [];
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final userId = authController.appwriteUser!.$id;
      developer.log(
        'Loading loans to repay for user ID: $userId',
        name: 'ContributionController',
      );

      // Get all contributions to campaigns hosted by the current user
      final loansToRepay = await _httpApiService.getLoansToRepay(userId);

      developer.log(
        'Successfully loaded ${loansToRepay.length} loans to repay',
        name: 'ContributionController',
      );
      if (loansToRepay.isNotEmpty) {
        for (var loan in loansToRepay) {
          developer.log(
            'Loan: ${loan.amount} from ${loan.contributorName} for campaign ${loan.campaignId}',
            name: 'ContributionController',
          );
        }
      } else {
        developer.log(
          'No loans to repay found for user $userId',
          name: 'ContributionController',
        );
      }

      return loansToRepay;
    } catch (e) {
      _errorMessage.value = e.toString();
      developer.log(
        'Error loading loans to repay: $e',
        name: 'ContributionController',
      );
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load contributions for a specific campaign
  Future<List<Contribution>> loadCampaignContributions(
    String campaignId,
  ) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final contributions = await _httpApiService.getCampaignContributions(
        campaignId,
      );

      developer.log(
        'Loaded ${contributions.length} contributions for campaign $campaignId',
        name: 'ContributionController',
      );
      return contributions;
    } catch (e) {
      _errorMessage.value = e.toString();
      developer.log(
        'Error loading campaign contributions: $e',
        name: 'ContributionController',
      );
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update contribution status (e.g., mark loan as repaid)
  Future<bool> updateContributionStatus(
    String contributionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final authController = AuthController.instance;
      final userId = authController.isAuthenticated
          ? authController.appwriteUser?.$id
          : null;

      final updatedContribution = await _httpApiService.updateContribution(
        contributionId,
        updates,
        userId: userId,
      );

      // Update local contribution if it exists
      final index = _contributions.indexWhere((c) => c.id == contributionId);
      if (index != -1) {
        _contributions[index] = updatedContribution;
      }

      // Update user contributions if it exists
      final userIndex = _userContributions.indexWhere(
        (c) => c.id == contributionId,
      );
      if (userIndex != -1) {
        _userContributions[userIndex] = updatedContribution;
      }

      Get.snackbar(
        'Success',
        'Contribution updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update contribution: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Mark a loan as repaid (convenience method)
  Future<bool> markLoanAsRepaid(String contributionId) async {
    return updateContributionStatus(contributionId, {
      'repaymentStatus': 'repaid',
      'repaidAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get contribution statistics for a campaign
  Map<String, dynamic> getCampaignContributionStats(
    List<Contribution> contributions,
  ) {
    final gifts = contributions.where((c) => c.type == 'gift').toList();
    final loans = contributions.where((c) => c.type == 'loan').toList();
    final pendingLoans = loans
        .where((c) => c.repaymentStatus == 'pending')
        .toList();
    final repaidLoans = loans
        .where((c) => c.repaymentStatus == 'repaid')
        .toList();
    final anonymousContributions = contributions
        .where((c) => c.isAnonymous)
        .toList();

    final totalAmount = contributions.fold<double>(
      0.0,
      (sum, c) => sum + c.amount,
    );
    final giftAmount = gifts.fold<double>(0.0, (sum, c) => sum + c.amount);
    final loanAmount = loans.fold<double>(0.0, (sum, c) => sum + c.amount);

    return {
      'totalContributions': contributions.length,
      'totalAmount': totalAmount,
      'gifts': {'count': gifts.length, 'amount': giftAmount},
      'loans': {
        'count': loans.length,
        'amount': loanAmount,
        'pending': pendingLoans.length,
        'repaid': repaidLoans.length,
      },
      'anonymous': {
        'count': anonymousContributions.length,
        'amount': anonymousContributions.fold<double>(
          0.0,
          (sum, c) => sum + c.amount,
        ),
      },
    };
  }

  /// Clear all data (useful for logout)
  void clearData() {
    _contributions.clear();
    _userContributions.clear();
    _errorMessage.value = '';
  }
}
