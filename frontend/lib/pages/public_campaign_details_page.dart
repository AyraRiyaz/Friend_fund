import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/campaign_controller.dart';
import '../controllers/contribution_controller.dart';
import '../theme/app_theme.dart';
import '../models/campaign.dart';
import '../widgets/contribution_modal.dart';

class PublicCampaignDetailsPage extends StatefulWidget {
  final String campaignId;

  const PublicCampaignDetailsPage({super.key, required this.campaignId});

  @override
  State<PublicCampaignDetailsPage> createState() =>
      _PublicCampaignDetailsPageState();
}

class _PublicCampaignDetailsPageState extends State<PublicCampaignDetailsPage> {
  final CampaignController _campaignController = Get.find<CampaignController>();
  final ContributionController _contributionController =
      Get.find<ContributionController>();

  Campaign? _campaign;
  List<Contribution> _contributions = [];
  bool _isLoading = true;
  bool _isLoadingContributions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load campaign details
      await _campaignController.loadCampaigns();
      final campaigns = _campaignController.campaigns;
      final campaign = campaigns.firstWhereOrNull(
        (c) => c.id == widget.campaignId,
      );

      if (campaign == null) {
        setState(() {
          _errorMessage = 'Campaign not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _campaign = campaign;
        _isLoading = false;
      });

      // Load contributions
      await _loadContributions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading campaign: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContributions() async {
    if (_campaign == null) return;

    setState(() {
      _isLoadingContributions = true;
    });

    try {
      final contributions = await _contributionController
          .loadCampaignContributions(_campaign!.id);
      setState(() {
        _contributions = contributions;
        // Update the campaign with the latest contributions
        _campaign = _campaign!.copyWith(contributions: contributions);
      });
    } catch (e) {
      print('Error loading contributions: $e');
    } finally {
      setState(() {
        _isLoadingContributions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading campaign details...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCampaignDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_campaign == null) {
      return const Scaffold(body: Center(child: Text('Campaign not found')));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.handshake, color: AppTheme.primaryBlue, size: 28),
            const SizedBox(width: 8),
            const Text('Campaign Details'),
          ],
        ),
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCampaignHeader(),
            const SizedBox(height: 16),
            _buildProgressSection(),
            const SizedBox(height: 16),
            _buildPublicContributions(),
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: _campaign!.status.toLowerCase() != 'closed'
          ? _buildContributeFAB()
          : null,
    );
  }

  Widget _buildCampaignHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.secondaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _campaign!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _campaign!.purpose,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _campaign!.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Hosted by ${_campaign!.hostName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(_campaign!.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (_campaign!.status.toLowerCase()) {
      case 'active':
        chipColor = AppTheme.success;
        statusText = 'Active';
        break;
      case 'closed':
        chipColor = Colors.grey;
        statusText = 'Closed';
        break;
      case 'paused':
      case 'inactive':
        chipColor = Colors.orange;
        statusText = 'Paused';
        break;
      default:
        chipColor = AppTheme.primaryBlue;
        statusText = _campaign!.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressPercentage = _campaign!.targetAmount > 0
        ? (_campaign!.collectedAmount / _campaign!.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remainingAmount =
        _campaign!.targetAmount - _campaign!.collectedAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Funding Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressPercentage >= 1.0
                        ? AppTheme.success
                        : AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressStat(
                      'Raised',
                      '₹${_formatAmount(_campaign!.collectedAmount)}',
                      AppTheme.success,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressStat(
                      'Goal',
                      '₹${_formatAmount(_campaign!.targetAmount)}',
                      AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressStat(
                      'Remaining',
                      '₹${_formatAmount(remainingAmount)}',
                      remainingAmount <= 0 ? AppTheme.success : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_contributions.length} supporters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(progressPercentage * 100).toInt()}% funded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPublicContributions() {
    if (_isLoadingContributions) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                CircularProgressIndicator(color: AppTheme.primaryBlue),
                const SizedBox(height: 20),
                Text(
                  'Loading supporters...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_contributions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 48,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No supporters yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to support this campaign!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Supporters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...(_contributions
                  .take(5)
                  .map(
                    (contribution) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(
                              0.1,
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contribution.contributorName,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(contribution.date),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹${_formatAmount(contribution.amount)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              if (_contributions.length > 5) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '+ ${_contributions.length - 5} more supporters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  Widget _buildContributeFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showContributionModal(),
      backgroundColor: AppTheme.primaryBlue,
      elevation: 6,
      icon: const Icon(Icons.favorite, color: Colors.white),
      label: const Text(
        'Contribute Now',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  void _showContributionModal() {
    if (_campaign == null) return;

    showDialog(
      context: context,
      builder: (context) => EnhancedContributionModal(
        campaignId: _campaign!.id,
        isFromQrCode: true,
      ),
    ).then((_) {
      // Refresh contributions after modal is closed
      _loadContributions();
    });
  }
}
