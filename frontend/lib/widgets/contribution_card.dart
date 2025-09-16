import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../theme/app_theme.dart';

class ContributionCard extends StatelessWidget {
  final Contribution contribution;
  final VoidCallback? onMarkRepaid;
  final bool showCampaignName;
  final String? campaignTitle;

  const ContributionCard({
    Key? key,
    required this.contribution,
    this.onMarkRepaid,
    this.showCampaignName = false,
    this.campaignTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCampaignName && campaignTitle != null) ...[
                    Text(
                      campaignTitle!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    contribution.contributorName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${contribution.amount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeChip(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(contribution.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (contribution.type == 'loan' &&
                      contribution.repaymentStatus != null) ...[
                    const SizedBox(height: 8),
                    _buildRepaymentStatus(),
                  ],
                ],
              ),
            ),
            if (contribution.type == 'loan' &&
                contribution.repaymentStatus == 'pending' &&
                onMarkRepaid != null) ...[
              const SizedBox(width: 16),
              _buildRepaidButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    if (contribution.type == 'loan') {
      iconData = Icons.handshake_outlined;
      iconColor = AppTheme.warning;
    } else {
      iconData = Icons.card_giftcard_outlined;
      iconColor = AppTheme.success;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }

  Widget _buildTypeChip() {
    Color chipColor = contribution.type == 'loan'
        ? AppTheme.warning
        : AppTheme.success;
    String chipText = contribution.type == 'loan' ? 'Loan' : 'Gift';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRepaymentStatus() {
    bool isPending = contribution.repaymentStatus == 'pending';
    Color statusColor = isPending ? AppTheme.warning : AppTheme.success;
    String statusText = isPending ? 'Pending Repayment' : 'Repaid';

    return Row(
      children: [
        Icon(
          isPending ? Icons.schedule : Icons.check_circle_outline,
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        if (isPending && contribution.repaymentDueDate != null) ...[
          const SizedBox(width: 8),
          Text(
            'Due: ${_formatDate(contribution.repaymentDueDate!)}',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildRepaidButton() {
    return TextButton(
      onPressed: onMarkRepaid,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.success,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text(
        'Mark Repaid',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
