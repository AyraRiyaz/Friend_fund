import 'package:flutter/material.dart';

class AppBarWithMenu extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuSelected;
  const AppBarWithMenu({Key? key, required this.title, this.onMenuSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            switch (value) {
              case 'my_campaigns':
                Navigator.pushNamed(context, '/my-campaigns');
                break;
              case 'campaigns':
                Navigator.pushNamed(context, '/home');
                break;
              case 'my_contributions':
                Navigator.pushNamed(context, '/my-contributions');
                break;
              case 'profile':
                Navigator.pushNamed(context, '/profile');
                break;
              case 'logout':
                Navigator.pushReplacementNamed(context, '/login');
                break;
            }
            if (onMenuSelected != null) onMenuSelected!();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'my_campaigns',
              child: Text('My Campaigns'),
            ),
            const PopupMenuItem(value: 'campaigns', child: Text('Campaigns')),
            const PopupMenuItem(
              value: 'my_contributions',
              child: Text('My Contributions'),
            ),
            const PopupMenuItem(
              value: 'profile',
              child: Text('Profile & Settings'),
            ),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.teal,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
