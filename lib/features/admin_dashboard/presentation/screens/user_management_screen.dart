import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/app_models.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedRole = 'All';
  final List<AdminUserItem> _users = [
    AdminUserItem(
      id: 'usr_001',
      displayName: 'Test User (Admin)',
      email: 'testuser@playhub.com',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    AdminUserItem(
      id: 'usr_002',
      displayName: 'Hitech Arena Manager',
      email: 'hitech.manager@sports.in',
      role: UserRole.businessOwner,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    AdminUserItem(
      id: 'usr_003',
      displayName: 'Rahul Sharma',
      email: 'rahul.s@gmail.com',
      role: UserRole.customer,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    AdminUserItem(
      id: 'usr_004',
      displayName: 'Anil Kumar',
      email: 'anil.k@outlook.com',
      role: UserRole.customer,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    AdminUserItem(
      id: 'usr_005',
      displayName: 'Sneha Patel',
      email: 'sneha.patel@gmail.com',
      role: UserRole.customer,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  void _showRoleChangeModal(AdminUserItem user) {
    UserRole chosenRole = user.role;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Role for ${user.displayName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(user.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Admin / Platform Superuser'),
                leading: Radio<UserRole>(
                  value: UserRole.admin,
                  // ignore: deprecated_member_use
                  groupValue: chosenRole,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setModalState(() => chosenRole = v!),
                ),
                onTap: () => setModalState(() => chosenRole = UserRole.admin),
              ),
              ListTile(
                title: const Text('Business Owner / Venue Operator'),
                leading: Radio<UserRole>(
                  value: UserRole.businessOwner,
                  // ignore: deprecated_member_use
                  groupValue: chosenRole,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setModalState(() => chosenRole = v!),
                ),
                onTap: () => setModalState(() => chosenRole = UserRole.businessOwner),
              ),
              ListTile(
                title: const Text('Customer / Player'),
                leading: Radio<UserRole>(
                  value: UserRole.customer,
                  // ignore: deprecated_member_use
                  groupValue: chosenRole,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setModalState(() => chosenRole = v!),
                ),
                onTap: () => setModalState(() => chosenRole = UserRole.customer),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      final idx = _users.indexWhere((u) => u.id == user.id);
                      if (idx != -1) {
                        _users[idx] = AdminUserItem(
                          id: user.id,
                          displayName: user.displayName,
                          email: user.email,
                          role: chosenRole,
                          isActive: user.isActive,
                          createdAt: user.createdAt,
                        );
                      }
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Updated role for ${user.displayName}')),
                    );
                  },
                  child: const Text('Save Role Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredUsers = _selectedRole == 'All'
        ? _users
        : _users.where((u) {
            if (_selectedRole == 'Admin') return u.role == UserRole.admin;
            if (_selectedRole == 'Business') return u.role == UserRole.businessOwner;
            return u.role == UserRole.customer;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management & RBAC', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Admin', 'Business', 'Player'].map((role) {
                final isSelected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedRole = role);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              separatorBuilder: (c, i) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final u = filteredUsers[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'U',
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(u.email, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: u.role == UserRole.admin
                                ? Colors.purple.shade50
                                : u.role == UserRole.businessOwner
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            u.role == UserRole.admin
                                ? 'ADMIN'
                                : u.role == UserRole.businessOwner
                                    ? 'BUSINESS OWNER'
                                    : 'PLAYER / USER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: u.role == UserRole.admin
                                  ? Colors.purple
                                  : u.role == UserRole.businessOwner
                                      ? Colors.blue.shade800
                                      : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      tooltip: 'Change Role',
                      onPressed: () => _showRoleChangeModal(u),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
