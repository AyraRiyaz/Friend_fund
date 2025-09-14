import 'package:flutter/material.dart';
import '../components/app_bar_with_menu.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'About FriendFund'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.handshake, size: 80, color: Colors.teal),
            ),
            const SizedBox(height: 24),

            // App Name and Version
            const Text(
              'FriendFund',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FriendFund bridges the gap between friends in need and those willing to help. We believe in the power of community support and making financial assistance transparent, secure, and accessible.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
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
                        color: Colors.teal,
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

            // Developer Info
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
                        color: Colors.teal,
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Open website
                          },
                          icon: const Icon(Icons.web),
                          label: const Text('Website'),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Open email
                          },
                          icon: const Icon(Icons.email),
                          label: const Text('Contact'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Show privacy policy
                          },
                          child: const Text('Privacy Policy'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Show terms of service
                          },
                          child: const Text('Terms of Service'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '© 2024 Pro26 Technologies. All rights reserved.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
            backgroundColor: Colors.teal.withOpacity(0.1),
            radius: 20,
            child: Icon(icon, color: Colors.teal, size: 20),
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
