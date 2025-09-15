import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/app_bar_with_menu.dart';
import '../controllers/auth_controller.dart';
import '../services/http_api_service.dart';
import '../models/campaign.dart';

class MyContributionsPage extends StatefulWidget {
  const MyContributionsPage({Key? key}) : super(key: key);

  @override
  State<MyContributionsPage> createState() => _MyContributionsPageState();
}

class _MyContributionsPageState extends State<MyContributionsPage> {
  List<Contribution> _contributions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final httpApiService = Get.find<HttpApiService>();
      final contributions = await httpApiService.getUserContributions(
        authController.appwriteUser!.$id,
      );

      setState(() {
        _contributions = contributions;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'My Contributions'),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadContributions,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Loading contributions...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load contributions',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadContributions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_contributions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No contributions yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start supporting campaigns to see your contributions here',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/home'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Campaigns'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contributions.length,
      itemBuilder: (context, index) {
        final contribution = _contributions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: contribution.type == 'loan'
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: Icon(
                contribution.type == 'loan'
                    ? Icons.handshake
                    : Icons.card_giftcard,
                color: contribution.type == 'loan'
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
            title: Text(
              'Campaign: ${contribution.campaignId}', // You might want to fetch campaign title
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ₹${contribution.amount.toStringAsFixed(0)}'),
                Text('Type: ${contribution.type.toUpperCase()}'),
                Text(
                  'Date: ${contribution.date.day}/${contribution.date.month}/${contribution.date.year}',
                ),
                if (contribution.type == 'loan' &&
                    contribution.repaymentStatus != null)
                  Text(
                    'Status: ${contribution.repaymentStatus!.toUpperCase()}',
                    style: TextStyle(
                      color: contribution.repaymentStatus == 'repaid'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            trailing:
                contribution.type == 'loan' &&
                    contribution.repaymentStatus == 'pending'
                ? IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _markAsRepaid(contribution),
                    tooltip: 'Mark as Repaid',
                  )
                : null,
            onTap: () {
              // Navigate to campaign details
              Get.toNamed('/campaign-details');
            },
          ),
        );
      },
    );
  }

  Future<void> _markAsRepaid(Contribution contribution) async {
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated) return;

    try {
      await HttpApiService().markLoanRepaid(
        contributionId: contribution.id,
        userId: authController.appwriteUser!.$id,
      );

      Get.snackbar(
        'Success',
        'Loan marked as repaid',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh the list
      _loadContributions();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark loan as repaid: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
