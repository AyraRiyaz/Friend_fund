import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../theme/app_theme.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onTap;
  final bool showProgress;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildPurposeChip(context),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  campaign.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showProgress) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(context),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${_formatAmount(campaign.collectedAmount)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryViolet,
                            ),
                      ),
                      Text(
                        'of ₹${_formatAmount(campaign.targetAmount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'by ${campaign.hostName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    _buildStatusBadge(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeChip(BuildContext context) {
    Color chipColor;
    switch (campaign.purpose.toLowerCase()) {
      case 'medical':
        chipColor = AppTheme.error;
        break;
      case 'education':
        chipColor = AppTheme.secondaryViolet;
        break;
      case 'emergency':
        chipColor = AppTheme.warning;
        break;
      case 'business':
        chipColor = AppTheme.accentViolet;
        break;
      default:
        chipColor = AppTheme.primaryViolet;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        campaign.purpose,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(campaign.progressPercentage * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryViolet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.grey.shade400,
            border: Border.all(color: Colors.grey.shade500, width: 0.3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: campaign.progressPercentage,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.5),
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: AppTheme.getStatusChipDecoration(campaign.status),
      child: Text(
        campaign.status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.getStatusColor(campaign.status),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
