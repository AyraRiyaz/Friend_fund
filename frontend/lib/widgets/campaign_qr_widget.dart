import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/campaign.dart';

class CampaignQRWidget extends StatelessWidget {
  final Campaign campaign;

  const CampaignQRWidget({Key? key, required this.campaign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contributionUrl =
        campaign.shareableUrl ??
        'https://your-app-domain.com/contribute/${campaign.id}';

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
        ],
      ),
    );
  }

  void _shareLink(String url) {
    Share.share(
      'Help ${campaign.hostName} reach their goal! Contribute to "${campaign.title}": $url',
      subject: 'Contribute to ${campaign.title}',
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
}
