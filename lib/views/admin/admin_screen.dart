import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item_model.dart';
import '../../models/user_model.dart';
import '../../theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/items_viewmodel.dart';
import '../widgets/admin_badge.dart';
import 'admin_items_screen.dart';
import 'admin_users_screen.dart';

/// Admin tab: overview numbers plus entry points to the admin tools.
/// Only built by MainShell when the signed-in user is an admin.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final Stream<List<UserModel>> _users;

  @override
  void initState() {
    super.initState();
    _users = context.read<AuthViewModel>().watchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthViewModel>().user;
    final items = context.watch<ItemsViewModel>();
    final active = items.all.where((i) => !i.isReturned).toList();
    final lost = active.where((i) => i.status == ItemStatus.lost).length;
    final found = active.length - lost;
    final pending = items.pendingClaimCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Admin Console',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            AdminBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Signed in as ${admin?.name ?? ''}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<UserModel>>(
          stream: _users,
          builder: (context, snap) {
            final users = snap.data;
            final total = users == null ? '-' : '${users.length}';
            final admins =
                users == null ? '-' : '${users.where((u) => u.isAdmin).length}';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    _StatCard(label: 'Total users', value: total),
                    _StatCard(label: 'Admins', value: admins),
                    _StatCard(label: 'Active posts', value: '${active.length}'),
                    _StatCard(
                      label: 'Pending claims',
                      value: '$pending',
                      highlight: pending > 0,
                    ),
                    _StatCard(
                      label: 'Lost',
                      value: '$lost',
                      color: AppColors.lost,
                    ),
                    _StatCard(
                      label: 'Found',
                      value: '$found',
                      color: AppColors.found,
                    ),
                  ],
                ),
                if (snap.hasError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'User totals unavailable. Check your connection and Firestore rules.',
                    style: TextStyle(color: AppColors.lost, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _NavTile(
          icon: Icons.group_outlined,
          title: 'Manage Users',
          subtitle: 'View accounts and change roles',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
          ),
        ),
        _NavTile(
          icon: Icons.fact_check_outlined,
          title: 'Moderate Items',
          subtitle: 'Review claims and remove posts',
          badge: pending,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminItemsScreen()),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.color = AppColors.text,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.accent : color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
