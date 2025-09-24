import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'Pro26 Technologies ("we", "our", or "us") is committed to protecting your privacy. '
            'This Privacy Policy explains how we collect, use, and safeguard your information when you use FriendFund.\n\n'
            'Information We Collect:\n'
            '• Personal information (name, email, phone number)\n'
            '• Financial information for transactions (UPI details)\n'
            '• Usage data and app analytics\n\n'
            'How We Use Information:\n'
            '• To provide and improve our services\n'
            '• To process transactions and maintain security\n'
            '• To send important notifications\n\n'
            'Data Security:\n'
            'We implement industry-standard security measures to protect your data. '
            'All transactions are encrypted and securely processed.\n\n'
            'Contact Us:\n'
            'If you have questions about this Privacy Policy, contact us at info@pro26technologies.com',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            'Welcome to FriendFund. By using our app, you agree to these terms.\n\n'
            'User Responsibilities:\n'
            '• Provide accurate information\n'
            '• Use the app for legitimate fundraising purposes only\n'
            '• Respect other users and maintain appropriate conduct\n'
            '• Honor loan repayment commitments\n\n'
            'App Usage:\n'
            '• FriendFund facilitates connections between users\n'
            '• We are not responsible for individual user transactions\n'
            '• Users are responsible for verifying campaign authenticity\n\n'
            'Prohibited Activities:\n'
            '• Fraudulent campaigns or false information\n'
            '• Harassment or inappropriate behavior\n'
            '• Misuse of personal information\n\n'
            'Limitation of Liability:\n'
            'Pro26 Technologies provides the platform "as is" and is not liable for disputes between users.\n\n'
            'For questions, contact: info@pro26technologies.com',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'About FriendFund',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // App Name and Version
            const Text(
              'FriendFund',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            // Mission Statement
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FriendFund bridges the gap between friends in need and those willing to help. We believe in the power of community support and making financial assistance transparent, secure, and accessible.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Key Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.campaign,
                      title: 'Create Campaigns',
                      description:
                          'Easily create fundraising campaigns for any cause',
                    ),
                    _buildFeatureItem(
                      icon: Icons.volunteer_activism,
                      title: 'Flexible Contributions',
                      description:
                          'Support through gifts or loans with repayment tracking',
                    ),
                    _buildFeatureItem(
                      icon: Icons.security,
                      title: 'Secure & Transparent',
                      description:
                          'All transactions are tracked with UTR verification',
                    ),
                    _buildFeatureItem(
                      icon: Icons.notifications,
                      title: 'Smart Notifications',
                      description: 'Automatic reminders for loan repayments',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Developer Info & Legal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Developed by',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pro26 Technologies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Innovative solutions for modern problems',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Divider(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),

                    // Legal buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => _showPrivacyPolicy(context),
                          child: const Text('Privacy Policy'),
                        ),
                        TextButton(
                          onPressed: () => _showTermsOfService(context),
                          child: const Text('Terms of Service'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '© 2025 Pro26 Technologies. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
