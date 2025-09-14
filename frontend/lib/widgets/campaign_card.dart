import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../theme/app_theme.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onTap;
  final bool showProgress;

  const CampaignCard({
    Key? key,
    required this.campaign,
    this.onTap,
    this.showProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPurposeChip(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                campaign.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showProgress) ...[
                const SizedBox(height: 16),
                _buildProgressBar(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${_formatAmount(campaign.collectedAmount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
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
                  _buildStatusBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeChip() {
    Color chipColor;
    switch (campaign.purpose.toLowerCase()) {
      case 'medical':
        chipColor = AppTheme.error;
        break;
      case 'education':
        chipColor = AppTheme.secondaryBlue;
        break;
      case 'emergency':
        chipColor = AppTheme.warning;
        break;
      case 'business':
        chipColor = AppTheme.accentBlue;
        break;
      default:
        chipColor = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        campaign.purpose,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: campaign.progressPercentage,
        minHeight: 8,
        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;

    switch (campaign.status.toLowerCase()) {
      case 'active':
        statusColor = AppTheme.success;
        statusText = 'Active';
        break;
      case 'closed':
        statusColor = AppTheme.textSecondary;
        statusText = 'Closed';
        break;
      default:
        statusColor = AppTheme.warning;
        statusText = 'Paused';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
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
