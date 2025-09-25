import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/campaign.dart';

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

    // Generate a URL that points to the public campaign details page
    // This will allow users to read campaign details before contributing
    final contributionUrl =
        widget.campaign.shareableUrl ??
        '${currentUri.scheme}://${currentUri.host}$port/campaign/${widget.campaign.id}';

    developer.log(
      'QR Code URL: $contributionUrl',
      name: 'CampaignQRWidget',
    ); // Debug log

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
            'Scan to view campaign',
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

  Future<void> _shareLink(String url) async {
    final shareText =
        'Help ${widget.campaign.hostName} reach their goal! Contribute to "${widget.campaign.title}": $url';

    try {
      // Use the share_plus package for proper sharing
      await Share.share(shareText, subject: 'Support ${widget.campaign.title}');

      developer.log('Campaign share dialog opened', name: 'CampaignQRWidget');
    } catch (e) {
      developer.log('Failed to share campaign: $e', name: 'CampaignQRWidget');

      // Fallback to copying to clipboard if sharing fails
      try {
        await Clipboard.setData(ClipboardData(text: shareText));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Sharing not available. Campaign details copied to clipboard instead!',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          );
        }
      } catch (clipboardError) {
        developer.log(
          'Failed to copy to clipboard as fallback: $clipboardError',
          name: 'CampaignQRWidget',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Share failed. Text: $shareText'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Campaign link copied to clipboard!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Failed to copy to clipboard: $e',
        name: 'CampaignQRWidget',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy link. URL: $url'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    }
  }
}
