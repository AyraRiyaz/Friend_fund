import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final Widget? floatingActionButton;
  final bool showDrawer;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    this.floatingActionButton,
    this.showDrawer = true,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.handshake, color: AppTheme.primaryBlue, size: 28),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
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
      ),
      drawer: widget.showDrawer ? _buildDrawer(context) : null,
      body: widget.child,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rahul Sharma',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '+91 98765 43210',
                  style: GoogleFonts.roboto(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () => _navigateTo(context, '/home'),
            isSelected: ModalRoute.of(context)?.settings.name == '/home',
          ),
          _buildDrawerItem(
            icon: Icons.folder_outlined,
            title: 'My Campaigns',
            onTap: () => _navigateTo(context, '/my-campaigns'),
            isSelected:
                ModalRoute.of(context)?.settings.name == '/my-campaigns',
          ),
          _buildDrawerItem(
            icon: Icons.handshake_outlined,
            title: 'My Contributions',
            onTap: () => _navigateTo(context, '/my-contributions'),
            isSelected:
                ModalRoute.of(context)?.settings.name == '/my-contributions',
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profile & Settings',
            onTap: () => _navigateTo(context, '/profile'),
            isSelected: ModalRoute.of(context)?.settings.name == '/profile',
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _navigateTo(context, '/login'),
            isSelected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pop(); // Close drawer
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }
}
