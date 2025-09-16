import 'package:flutter/material.dart';
import '../components/app_bar_with_menu.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Help & Support'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),

            _buildFAQItem(
              'How do I create a campaign?',
              'Tap the "+" button on the home screen or use the navigation drawer to access "Create Campaign". Fill in all required details including title, description, purpose, and target amount.',
            ),

            _buildFAQItem(
              'What types of contributions are available?',
              'FriendFund supports two types of contributions:\n• Gifts: One-time donations with no repayment required\n• Loans: Contributions that need to be repaid to the contributor',
            ),

            _buildFAQItem(
              'How do I make a contribution?',
              'Open any campaign and tap "Contribute". Choose between gift or loan, enter the amount, and upload a payment screenshot with UTR number for verification.',
            ),

            _buildFAQItem(
              'How do loan repayments work?',
              'For loans, you can set a due date. The app will track and remind contributors about repayments. Mark loans as repaid once payment is received.',
            ),

            _buildFAQItem(
              'Is my personal information secure?',
              'Yes, all data is securely stored using Appwrite backend with proper authentication and encryption. Your privacy is our priority.',
            ),

            const SizedBox(height: 30),

            // Contact Section
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),

            _buildContactCard(
              icon: Icons.email,
              title: 'Email Support',
              content: 'support@friendfund.pro26.in',
              onTap: () {
                // TODO: Open email app
              },
            ),

            _buildContactCard(
              icon: Icons.phone,
              title: 'Phone Support',
              content: '+91 98765 43210',
              onTap: () {
                // TODO: Open phone app
              },
            ),

            _buildContactCard(
              icon: Icons.chat,
              title: 'Live Chat',
              content: 'Available 9 AM - 6 PM IST',
              onTap: () {
                // TODO: Open chat support
              },
            ),

            const SizedBox(height: 30),

            // App Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'FriendFund',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Developed by Pro26',
                      style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.teal,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(content),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
