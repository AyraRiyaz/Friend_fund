import 'package:get/get.dart';
import '../services/http_api_service.dart';
import '../models/loan_repayment.dart';
import 'auth_controller.dart';

class LoanRepaymentController extends GetxController {
  static LoanRepaymentController get instance => Get.find();

  // Get HTTP API service instance
  HttpApiService get _httpApiService => Get.find<HttpApiService>();

  // Observables
  final RxList<LoanRepayment> _userRepayments = <LoanRepayment>[].obs;
  final RxList<LoanRepayment> _receivedRepayments = <LoanRepayment>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<LoanRepayment> get userRepayments => _userRepayments;
  List<LoanRepayment> get receivedRepayments => _receivedRepayments;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadUserRepayments();
    loadReceivedRepayments();
  }

  /// Create a new loan repayment
  Future<LoanRepayment?> createLoanRepayment({
    required String loanContributionId,
    required double amount,
    required String utr,
    required String paymentScreenshotUrl,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final authController = AuthController.instance;
      if (!authController.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authController.appwriteUser!.$id;

      final repaymentData = {
        'loanContributionId': loanContributionId,
        'repayerId': userId,
        'amount': amount,
        'utr': utr,
        'paymentScreenshotUrl': paymentScreenshotUrl,
        'status': 'pending',
      };

      print('Creating loan repayment with data: $repaymentData');

      final repayment = await _httpApiService.createLoanRepayment(
        repaymentData,
      );

      // Add to local list
      _userRepayments.add(repayment);

      // Also update the original loan contribution status
      await _httpApiService.updateContribution(loanContributionId, {
        'repaymentStatus': 'repayment_submitted',
      }, userId: userId);

      Get.snackbar(
        'Success',
        'Loan repayment submitted successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return repayment;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to submit loan repayment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load user's loan repayments (loans they have repaid)
  Future<void> loadUserRepayments() async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final repayments = await _httpApiService.getUserLoanRepayments(
        authController.appwriteUser!.$id,
      );
      _userRepayments.assignAll(repayments);

      print('Loaded ${repayments.length} user loan repayments');
    } catch (e) {
      _errorMessage.value = e.toString();
      print('Error loading user loan repayments: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load loan repayments received (loans repaid to the user)
  Future<void> loadReceivedRepayments() async {
    final authController = AuthController.instance;
    if (!authController.isAuthenticated) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final repayments = await _httpApiService.getReceivedLoanRepayments(
        authController.appwriteUser!.$id,
      );
      _receivedRepayments.assignAll(repayments);

      print('Loaded ${repayments.length} received loan repayments');
    } catch (e) {
      _errorMessage.value = e.toString();
      print('Error loading received loan repayments: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get loan repayments for a specific loan contribution
  Future<List<LoanRepayment>> getLoanRepayments(
    String loanContributionId,
  ) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final repayments = await _httpApiService.getLoanRepaymentsByLoanId(
        loanContributionId,
      );

      print(
        'Loaded ${repayments.length} repayments for loan $loanContributionId',
      );
      return repayments;
    } catch (e) {
      _errorMessage.value = e.toString();
      print('Error loading loan repayments for loan $loanContributionId: $e');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  /// Verify a loan repayment (admin function)
  Future<bool> verifyLoanRepayment(String repaymentId, bool isApproved) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final updatedRepayment = await _httpApiService.verifyLoanRepayment(
        repaymentId,
        isApproved,
      );

      // Update local repayment if it exists
      final userIndex = _userRepayments.indexWhere((r) => r.id == repaymentId);
      if (userIndex != -1) {
        _userRepayments[userIndex] = updatedRepayment;
      }

      final receivedIndex = _receivedRepayments.indexWhere(
        (r) => r.id == repaymentId,
      );
      if (receivedIndex != -1) {
        _receivedRepayments[receivedIndex] = updatedRepayment;
      }

      // If approved, update the original loan contribution to repaid
      if (isApproved) {
        await _httpApiService.updateContribution(
          updatedRepayment.loanContributionId,
          {
            'repaymentStatus': 'repaid',
            'repaidAt': DateTime.now().toIso8601String(),
          },
        );
      }

      Get.snackbar(
        'Success',
        isApproved
            ? 'Loan repayment verified successfully!'
            : 'Loan repayment rejected',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to verify loan repayment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get pending repayments that need verification
  List<LoanRepayment> get pendingRepayments {
    return _receivedRepayments.where((r) => r.isPending).toList();
  }

  /// Get verified repayments
  List<LoanRepayment> get verifiedRepayments {
    return _receivedRepayments.where((r) => r.isVerified).toList();
  }

  /// Get failed/rejected repayments
  List<LoanRepayment> get failedRepayments {
    return _receivedRepayments.where((r) => r.isRejected).toList();
  }

  /// Get repayment statistics
  Map<String, dynamic> getRepaymentStats() {
    final totalRepayments = _userRepayments.length;
    final pendingCount = _userRepayments.where((r) => r.isPending).length;
    final verifiedCount = _userRepayments.where((r) => r.isVerified).length;
    final failedCount = _userRepayments.where((r) => r.isRejected).length;

    final totalAmount = _userRepayments.fold<double>(
      0.0,
      (sum, r) => sum + r.amount,
    );
    final verifiedAmount = _userRepayments
        .where((r) => r.isVerified)
        .fold<double>(0.0, (sum, r) => sum + r.amount);

    return {
      'totalRepayments': totalRepayments,
      'pending': pendingCount,
      'verified': verifiedCount,
      'failed': failedCount,
      'totalAmount': totalAmount,
      'verifiedAmount': verifiedAmount,
    };
  }

  /// Refresh all repayment data
  Future<void> refreshAll() async {
    await Future.wait([loadUserRepayments(), loadReceivedRepayments()]);
  }

  /// Clear all data (useful for logout)
  void clearData() {
    _userRepayments.clear();
    _receivedRepayments.clear();
    _errorMessage.value = '';
  }
}
