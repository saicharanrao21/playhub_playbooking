import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'John Doe',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'john.doe@example.com',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(context, Icons.calendar_today, 'My Bookings', () {}),
          _buildMenuItem(context, Icons.favorite_border, 'Favorites', () {}),
          _buildMenuItem(context, Icons.payment, 'Payments', () {}),
          _buildMenuItem(
            context,
            Icons.notifications_none,
            'Notifications',
            () {},
          ),
          const Divider(),
          _buildMenuItem(
            context,
            Icons.business_center_outlined,
            'Switch to Business Mode',
            () => context.push('/business-dashboard'),
          ),
          _buildMenuItem(
            context,
            Icons.admin_panel_settings_outlined,
            'Admin Dashboard',
            () => context.push('/admin-dashboard'),
          ),
          const Divider(),
          _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {}),
          _buildMenuItem(
            context,
            Icons.logout,
            'Logout',
            () => context.go('/login'),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
