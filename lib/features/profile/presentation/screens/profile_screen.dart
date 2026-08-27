import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/security/auth_provider.dart';
import '../../../../core/models/app_models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.identity;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Guest User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'Not logged in',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (user != null) ...[
                  const SizedBox(height: 8),
                  Chip(label: Text(user.role.name.toUpperCase())),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(
            context,
            Icons.calendar_today,
            'My Bookings',
            () => context.push('/bookings'),
          ),
          _buildMenuItem(context, Icons.favorite_border, 'Favorites', () {}),
          _buildMenuItem(context, Icons.payment, 'Payments', () {}),
          _buildMenuItem(
            context,
            Icons.notifications_none,
            'Notifications',
            () => context.push('/notifications'),
          ),
          _buildMenuItem(
            context,
            Icons.notifications_active_outlined,
            'Notification Preferences',
            () => context.push('/profile/notifications'),
          ),
          const Divider(),
          if (ref.hasRole(UserRole.businessOwner) || ref.hasRole(UserRole.admin))
            _buildMenuItem(
              context,
              Icons.business_center_outlined,
              'Switch to Business Mode',
              () => context.push('/business-dashboard'),
            ),
          if (ref.hasRole(UserRole.admin))
            _buildMenuItem(
              context,
              Icons.admin_panel_settings_outlined,
              'Admin Dashboard',
              () => context.push('/admin-dashboard'),
            ),
          const Divider(),
          _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {}),
          _buildMenuItem(context, Icons.logout, 'Logout', () {
            ref.read(authStateProvider.notifier).logout();
            // Redirect will be handled by GoRouter
          }, color: Colors.red),
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
