import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'add_campaign_modal.dart';

class AppBarWithMenu extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuSelected;
  const AppBarWithMenu({super.key, required this.title, this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.handshake, color: AppTheme.primaryBlue, size: 28),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Show notifications
          },
        ),
        const SizedBox(width: 8),
      ],
      elevation: 0,
      backgroundColor: AppTheme.surfaceWhite,
      foregroundColor: AppTheme.primaryBlue,
      iconTheme: IconThemeData(color: AppTheme.primaryBlue),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
      child: Column(
        children: [
          // Header
          Obx(() {
            final user = authController.userProfile;
            final appwriteUser = authController.appwriteUser;

            return UserAccountsDrawerHeader(
              accountName: Text(
                user?.name ?? appwriteUser?.name ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                user?.email ?? appwriteUser?.email ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: user?.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImage!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(user.name),
                        ),
                      )
                    : _buildDefaultAvatar(
                        user?.name ?? appwriteUser?.name ?? 'U',
                      ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          }),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    Get.offAllNamed('/home');
                  },
                  isSelected: Get.currentRoute == '/home',
                ),
                _buildDrawerItem(
                  icon: Icons.campaign_outlined,
                  title: 'My Campaigns',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed('/my-campaigns');
                  },
                  isSelected: Get.currentRoute == '/my-campaigns',
                ),
                _buildDrawerItem(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'My Contributions',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed('/my-contributions');
                  },
                  isSelected: Get.currentRoute == '/my-contributions',
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline,
                  title: 'Create Campaign',
                  onTap: () {
                    Navigator.pop(context);
                    showAddCampaignModal(context);
                  },
                  isSelected: Get.currentRoute == '/add-campaign',
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile & Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed('/profile');
                  },
                  isSelected: Get.currentRoute == '/profile',
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed('/help');
                  },
                  isSelected: Get.currentRoute == '/help',
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed('/about');
                  },
                  isSelected: Get.currentRoute == '/about',
                ),
              ],
            ),
          ),

          // Logout
          const Divider(),
          Obx(
            () => _buildDrawerItem(
              icon: Icons.logout,
              title: authController.isLoading ? 'Logging out...' : 'Logout',
              onTap: authController.isLoading
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await authController.logout();
                      Get.offAllNamed('/login');
                    },
              textColor: Colors.red[600],
              iconColor: Colors.red[600],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'U',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isSelected = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ?? (isSelected ? AppTheme.primaryBlue : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              textColor ??
              (isSelected ? AppTheme.primaryBlue : Colors.grey[800]),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
