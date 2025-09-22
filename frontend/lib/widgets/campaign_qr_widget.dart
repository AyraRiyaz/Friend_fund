import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
// import 'package:share_plus/share_plus.dart'; // Temporarily disabled for web
import '../models/campaign.dart';
import 'contribution_modal.dart';

class CampaignQRWidget extends StatefulWidget {
  final Campaign campaign;

  const CampaignQRWidget({super.key, required this.campaign});

  @override
  State<CampaignQRWidget> createState() => _CampaignQRWidgetState();
}

class _CampaignQRWidgetState extends State<CampaignQRWidget> {
  @override
  Widget build(BuildContext context) {
    // For development mode, use a URL that will open the contribution modal
    // In production, this should be your actual domain
    final currentUri = Uri.base;
    final port = currentUri.port != 80 && currentUri.port != 443
        ? ':${currentUri.port}'
        : '';

    // Generate a URL that points to the contribution modal
    // This will work when the QR code is scanned by opening the contribution modal
    final contributionUrl =
        widget.campaign.shareableUrl ??
        '${currentUri.scheme}://${currentUri.host}$port/modal/contribute/${widget.campaign.id}';

    print('QR Code URL: $contributionUrl'); // Debug print

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share Campaign',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: contributionUrl,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Scan to contribute',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareLink(contributionUrl),
              icon: const Icon(Icons.share),
              label: const Text('Share Link'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Copy link button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _copyLink(context, contributionUrl),
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
            ),
          ),

          const SizedBox(height: 8),

          // Test button for development
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _testQRCode(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Test QR Code (Dev)'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _shareLink(String url) {
    // Temporarily disabled for web compatibility - Share functionality will be available in mobile app
    print(
      'Would share: Help ${widget.campaign.hostName} reach their goal! Contribute to "${widget.campaign.title}": $url',
    );
  }

  void _copyLink(BuildContext context, String url) {
    // For web, we would use html.window.navigator.clipboard?.writeText(url)
    // For mobile, we would use Clipboard.setData()
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied: $url'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _testQRCode(BuildContext context) {
    // Open the contribution modal to test QR code functionality
    showDialog(
      context: context,
      builder: (context) =>
          EnhancedContributionModal(campaignId: widget.campaign.id),
    );
  }
}
