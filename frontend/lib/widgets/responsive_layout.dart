import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? floatingActionButton;
  final List<Widget>? appBarActions;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.title,
    this.floatingActionButton,
    this.appBarActions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed navigation sidebar
          const SizedBox(width: 280, child: NavigationSidebar()),
          // Main content area - no app bar, with top padding
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: child,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildMobileAppBar(context),
      drawer: const Drawer(width: 280, child: NavigationSidebar()),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.handshake, color: AppTheme.primaryBlue, size: 28),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
        ],
      ),
      actions: [
        ...?appBarActions,
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
}

class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
        border: Border(
          right: BorderSide(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Modern App Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FriendFund',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Fundraising Platform',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Professional User Profile Section
          Obx(() {
            final user = authController.userProfile;
            final appwriteUser = authController.appwriteUser;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.secondaryBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: user?.profileImage != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.profileImage!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildDefaultAvatar(user.name),
                                  ),
                                )
                              : _buildDefaultAvatar(
                                  user?.name ?? appwriteUser?.name ?? 'U',
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? appwriteUser?.name ?? 'User',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? appwriteUser?.email ?? '',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Online',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Fixed Navigation Items (No Scrolling, No Headings)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  // Navigation Items without grouping headers
                  _buildNavigationItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () => _handleNavigation(
                      context,
                      () => Get.offAllNamed('/home'),
                    ),
                    isSelected: Get.currentRoute == '/home',
                  ),
                  _buildNavigationItem(
                    icon: Icons.campaign_rounded,
                    title: 'My Campaigns',
                    onTap: () => _handleNavigation(
                      context,
                      () => Get.toNamed('/my-campaigns'),
                    ),
                    isSelected: Get.currentRoute == '/my-campaigns',
                  ),
                  _buildNavigationItem(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'My Contributions',
                    onTap: () => _handleNavigation(
                      context,
                      () => Get.toNamed('/my-contributions'),
                    ),
                    isSelected: Get.currentRoute == '/my-contributions',
                  ),

                  const SizedBox(height: 12),

                  // Subtle divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildNavigationItem(
                    icon: Icons.person_rounded,
                    title: 'Profile & Settings',
                    onTap: () => _handleNavigation(
                      context,
                      () => Get.toNamed('/profile'),
                    ),
                    isSelected: Get.currentRoute == '/profile',
                  ),
                  _buildNavigationItem(
                    icon: Icons.help_rounded,
                    title: 'Help & Support',
                    onTap: () =>
                        _handleNavigation(context, () => Get.toNamed('/help')),
                    isSelected: Get.currentRoute == '/help',
                  ),
                  _buildNavigationItem(
                    icon: Icons.info_rounded,
                    title: 'About',
                    onTap: () =>
                        _handleNavigation(context, () => Get.toNamed('/about')),
                    isSelected: Get.currentRoute == '/about',
                  ),

                  // Spacer to push logout to bottom
                  const Spacer(),
                ],
              ),
            ),
          ), // Enhanced Logout Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(
              () => _buildNavigationItem(
                icon: Icons.logout_rounded,
                title: authController.isLoading ? 'Logging out...' : 'Logout',
                onTap: authController.isLoading
                    ? null
                    : () => _handleNavigation(context, () async {
                        await authController.logout();
                        Get.offAllNamed('/login');
                      }),
                textColor: Colors.red[600],
                iconColor: Colors.red[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, VoidCallback navigationAction) {
    // Check if we're in mobile view (drawer is open)
    if (MediaQuery.of(context).size.width < 768 &&
        Scaffold.of(context).hasDrawer) {
      Navigator.pop(context); // Close drawer first
    }
    navigationAction(); // Then navigate
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

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isSelected = false,
    bool isAccent = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                  : isAccent
                  ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isAccent && !isSelected
                  ? Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      iconColor ??
                      (isSelected
                          ? AppTheme.primaryBlue
                          : isAccent
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          textColor ??
                          (isSelected
                              ? AppTheme.primaryBlue
                              : isAccent
                              ? AppTheme.primaryBlue
                              : AppTheme.textPrimary),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : isAccent
                          ? FontWeight.w500
                          : FontWeight.w400,
                      fontSize: 13,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
