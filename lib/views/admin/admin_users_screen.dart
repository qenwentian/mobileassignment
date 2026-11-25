import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/admin_badge.dart';

enum _RoleFilter { all, admins, normal }

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final Stream<List<UserModel>> _stream;
  String _query = '';
  _RoleFilter _filter = _RoleFilter.all;

  @override
  void initState() {
    super.initState();
    _stream = context.read<AuthViewModel>().watchAllUsers();
  }

  bool _matches(UserModel u) {
    final roleOk = switch (_filter) {
      _RoleFilter.all => true,
      _RoleFilter.admins => u.isAdmin,
      _RoleFilter.normal => !u.isAdmin,
    };
    final q = _query.trim().toLowerCase();
    final queryOk = q.isEmpty ||
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.studentId.toLowerCase().contains(q);
    return roleOk && queryOk;
  }

  Future<void> _changeRole(UserModel target) async {
    final promote = !target.isAdmin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(promote ? 'Make admin?' : 'Remove admin?'),
        content: Text(
          promote
              ? '${target.name} will be able to manage users and moderate items.'
              : '${target.name} will lose admin access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(promote ? 'Make admin' : 'Remove admin'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final err = await context.read<AuthViewModel>().updateUserRole(
          target.id,
          promote ? UserRole.admin : UserRole.normal,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              '${target.name} is now ${promote ? 'an admin' : 'a normal user'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthViewModel>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: AppColors.muted),
                  hintText: 'Search name, email or student ID',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in _RoleFilter.values)
                    ChoiceChip(
                      label: Text(switch (f) {
                        _RoleFilter.all => 'All',
                        _RoleFilter.admins => 'Admins',
                        _RoleFilter.normal => 'Normal users',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: _stream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text(
                          'Could not load users. Check your connection and Firestore rules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.lost),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snap.data!.where(_matches).toList();
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'No users match.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (_, i) => _UserTile(
                        user: users[i],
                        isSelf: users[i].id == me?.id,
                        onChangeRole: () => _changeRole(users[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isSelf,
    required this.onChangeRole,
  });

  final UserModel user;
  final bool isSelf;
  final VoidCallback onChangeRole;

  @override
  Widget build(BuildContext context) {
    final builtIn = AuthService.isBuiltInAdminEmail(user.email);
    final initial =
        user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceAlt,
            child: Text(initial, style: const TextStyle(color: AppColors.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 8),
                      const AdminBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (user.studentId.isNotEmpty)
                  Text(
                    'ID: ${user.studentId}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (isSelf || builtIn)
            Text(
              isSelf ? 'You' : 'Built-in',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            TextButton(
              onPressed: onChangeRole,
              child: Text(user.isAdmin ? 'Remove admin' : 'Make admin'),
            ),
        ],
      ),
    );
  }
}
