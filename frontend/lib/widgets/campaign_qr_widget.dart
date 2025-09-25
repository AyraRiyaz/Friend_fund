import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campaign.dart';
import '../theme/app_theme.dart';
import '../config/appwrite_config.dart';

class CampaignQRWidget extends StatefulWidget {
  final Campaign campaign;

  const CampaignQRWidget({super.key, required this.campaign});

  @override
  State<CampaignQRWidget> createState() => _CampaignQRWidgetState();
}

class _CampaignQRWidgetState extends State<CampaignQRWidget> {
  @override
  Widget build(BuildContext context) {
    // Generate a URL that points to the public campaign details page on the deployed site
    // This will allow users to read campaign details before contributing
    // Always use the deployed site URL, regardless of shareableUrl value
    final contributionUrl =
        '${AppwriteConfig.webPlatform}/campaign/${widget.campaign.id}';

    developer.log(
      'QR Code URL: $contributionUrl',
      name: 'CampaignQRWidget',
    ); // Debug log

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration.copyWith(
        boxShadow: AppTheme.cardShadowLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.share_rounded,
                  color: AppTheme.primaryViolet,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Share Campaign',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryViolet.withValues(alpha: 0.2),
              ),
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
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareLink(contributionUrl),
              icon: const Icon(Icons.share_rounded),
              label: Text(
                'Share Link',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Copy link button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyLink(context, contributionUrl),
              icon: const Icon(Icons.copy_rounded),
              label: Text(
                'Copy Link',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryViolet,
                side: BorderSide(color: AppTheme.primaryViolet),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
