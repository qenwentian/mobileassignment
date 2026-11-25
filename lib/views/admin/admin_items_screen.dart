import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item_model.dart';
import '../../models/user_model.dart';
import '../../theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/items_viewmodel.dart';
import '../widgets/item_card.dart';

enum _ItemFilter { all, pending, lost, found, returned }

class AdminItemsScreen extends StatefulWidget {
  const AdminItemsScreen({super.key});

  @override
  State<AdminItemsScreen> createState() => _AdminItemsScreenState();
}

class _AdminItemsScreenState extends State<AdminItemsScreen> {
  late final Stream<List<UserModel>> _users;
  _ItemFilter _filter = _ItemFilter.all;

  @override
  void initState() {
    super.initState();
    _users = context.read<AuthViewModel>().watchAllUsers();
  }

  bool _matches(ItemModel i, _ItemFilter f) => switch (f) {
        _ItemFilter.all => true,
        _ItemFilter.pending => i.isClaimed && !i.isReturned,
        _ItemFilter.lost => i.status == ItemStatus.lost && !i.isReturned,
        _ItemFilter.found => i.status == ItemStatus.found && !i.isReturned,
        _ItemFilter.returned => i.isReturned,
      };

  String _label(_ItemFilter f) => switch (f) {
        _ItemFilter.all => 'All',
        _ItemFilter.pending => 'Pending claims',
        _ItemFilter.lost => 'Lost',
        _ItemFilter.found => 'Found',
        _ItemFilter.returned => 'Returned',
      };

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  void _toast(String? error, String success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? success)),
    );
  }

  Future<void> _approve(ItemModel item) async {
    final ok = await _confirm(
      title: 'Approve claim?',
      body: 'Mark "${item.name}" as returned to the claimant. '
          'It will be removed from the public feed and map.',
      action: 'Approve',
    );
    if (!ok || !mounted) return;
    final err = context
        .read<ItemsViewModel>()
        .approveClaim(item.id, context.read<AuthViewModel>().user);
    _toast(err, 'Claim approved. Item marked as returned.');
  }

  Future<void> _reject(ItemModel item) async {
    final ok = await _confirm(
      title: 'Reject claim?',
      body: 'The claim on "${item.name}" will be cleared so it can be claimed again.',
      action: 'Reject',
    );
    if (!ok || !mounted) return;
    final err = context
        .read<ItemsViewModel>()
        .rejectClaim(item.id, context.read<AuthViewModel>().user);
    _toast(err, 'Claim rejected.');
  }

  Future<void> _delete(ItemModel item) async {
    final ok = await _confirm(
      title: 'Delete post?',
      body: '"${item.name}" will be permanently removed.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    final err = context
        .read<ItemsViewModel>()
        .deleteItem(item.id, context.read<AuthViewModel>().user);
    _toast(err, 'Post deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemsViewModel>();
    final all = vm.all;
    final items = all.where((i) => _matches(i, _filter)).toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Moderate Items')),
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: _users,
          builder: (context, snap) {
            final people = {
              for (final u in snap.data ?? const <UserModel>[]) u.id: u,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    children: [
                      for (final f in _ItemFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '${_label(f)} (${all.where((i) => _matches(i, f)).length})',
                            ),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'Nothing here.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _AdminItemCard(
                            item: items[i],
                            poster: people[items[i].ownerId],
                            claimant: people[items[i].claimedBy],
                            onOpen: () => Navigator.pushNamed(
                              context,
                              '/details',
                              arguments: items[i].id,
                            ),
                            onApprove: () => _approve(items[i]),
                            onReject: () => _reject(items[i]),
                            onDelete: () => _delete(items[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminItemCard extends StatelessWidget {
  const _AdminItemCard({
    required this.item,
    required this.poster,
    required this.claimant,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final ItemModel item;
  final UserModel? poster;
  final UserModel? claimant;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  String _who(UserModel? u) =>
      u == null ? 'Unknown user' : '${u.name} (${u.studentId.isEmpty ? u.email : u.studentId})';

  @override
  Widget build(BuildContext context) {
    final pending = item.isClaimed && !item.isReturned;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pending ? AppColors.accent : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusTag(item.status),
                    if (item.isReturned) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'RETURNED',
                        style: TextStyle(
                          color: AppColors.found,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else if (pending) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'CLAIM PENDING',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.locationDetail,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Posted by: ${_who(poster)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (item.isClaimed)
                  Text(
                    'Claimed by: ${_who(claimant)}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (pending) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ] else
                const Spacer(),
              IconButton(
                tooltip: 'Delete post',
                icon: const Icon(Icons.delete_outline, color: AppColors.lost),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
