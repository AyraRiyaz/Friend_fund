import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/loan_repayment.dart';
import '../controllers/loan_repayment_controller.dart';
import '../theme/app_theme.dart';

class LoanRepaymentListWidget extends StatefulWidget {
  final String? loanContributionId; // Optional filter for specific loan
  final bool
  showUserRepayments; // Show user's repayments or received repayments

  const LoanRepaymentListWidget({
    super.key,
    this.loanContributionId,
    this.showUserRepayments = true,
  });

  @override
  State<LoanRepaymentListWidget> createState() =>
      _LoanRepaymentListWidgetState();
}

class _LoanRepaymentListWidgetState extends State<LoanRepaymentListWidget> {
  final LoanRepaymentController _controller =
      Get.find<LoanRepaymentController>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepayments();
  }

  Future<void> _loadRepayments() async {
    setState(() => _isLoading = true);
    await _controller.refreshAll();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<LoanRepayment> repayments = widget.showUserRepayments
          ? _controller.userRepayments
          : _controller.receivedRepayments;

      // Filter by specific loan if provided
      if (widget.loanContributionId != null) {
        repayments = repayments
            .where((r) => r.loanContributionId == widget.loanContributionId)
            .toList();
      }

      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (repayments.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: _loadRepayments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: repayments.length,
          itemBuilder: (context, index) {
            final repayment = repayments[index];
            return _buildRepaymentCard(repayment);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.showUserRepayments
                  ? Icons.payment_outlined
                  : Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.showUserRepayments
                  ? 'No Loan Repayments Made'
                  : 'No Loan Repayments Received',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showUserRepayments
                  ? 'Loan repayments you make will appear here'
                  : 'Loan repayments made to you will appear here',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentCard(LoanRepayment repayment) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (repayment.status) {
      case 'verified':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        statusText = 'VERIFIED';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'PENDING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with amount and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${repayment.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryViolet,
                          letterSpacing: -0.25,
                        ),
                      ),
                      Text(
                        widget.showUserRepayments
                            ? 'Repaid to Lender'
                            : 'Repaid by User',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Repayment details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryViolet.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Repayment Date:',
                    _formatDate(repayment.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Reference:', repayment.utr),
                ],
              ),
            ),

            // Action buttons for pending repayments (admin only)
            if (repayment.isPending && !widget.showUserRepayments) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyRepayment(repayment, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyRepayment(repayment, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // View payment proof button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewPaymentProof(repayment),
                icon: const Icon(Icons.receipt),
                label: const Text('View Payment Proof'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryViolet,
                  side: BorderSide(color: AppTheme.primaryViolet),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  Future<void> _verifyRepayment(
    LoanRepayment repayment,
    bool isApproved,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'Approve Repayment' : 'Reject Repayment'),
        content: Text(
          isApproved
              ? 'Are you sure you want to approve this repayment of ₹${repayment.amount.toStringAsFixed(0)}?'
              : 'Are you sure you want to reject this repayment? Please provide a reason.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? AppTheme.success : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _controller.verifyLoanRepayment(
          repayment.id,
          isApproved,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isApproved
                    ? 'Repayment approved successfully!'
                    : 'Repayment rejected successfully!',
              ),
              backgroundColor: isApproved ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _viewPaymentProof(LoanRepayment repayment) {
    if (repayment.paymentScreenshotUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment proof available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Proof'),
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  repayment.paymentScreenshotUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: const Column(
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Failed to load payment proof'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display loan repayment statistics
class LoanRepaymentStatsWidget extends StatelessWidget {
  const LoanRepaymentStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanRepaymentController>();

    return Obx(() {
      final stats = controller.getRepaymentStats();

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryViolet.withValues(alpha: 0.1),
              AppTheme.secondaryViolet.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryViolet.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Repayment Summary',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Repayments',
                    stats['totalRepayments'].toString(),
                    Icons.payment,
                    AppTheme.primaryViolet,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Verified Amount',
                    '₹${stats['verifiedAmount'].toStringAsFixed(0)}',
                    Icons.verified,
                    AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Pending',
                    stats['pending'].toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Failed',
                    stats['failed'].toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
