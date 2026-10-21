import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/items_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';
import 'widgets/item_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final items = context.watch<ItemsViewModel>();
    final posts = items.activePostsOf(user);
    final claims = items.claimHistoryOf(user);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          const Expanded(
              child: Text('Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.accent),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const SafeArea(
                child: ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Notifications'),
                  subtitle: Text('Settings will appear here in a later release.'),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Text(user?.name ?? '',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('ID: ${user?.studentId ?? ''}',
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 12),
        _section(context, 'Active Posts (${posts.length})', posts,
            'You have no active posts.'),
        _section(context, 'Claim History', claims, 'No claims yet.'),
        const SizedBox(height: 40),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: AppColors.lost,
            side: const BorderSide(color: AppColors.lost),
          ),
          onPressed: () {
            context.read<NavViewModel>().reset();
            context.read<AuthViewModel>().logout(); // root swaps to Login
          },
          child: const Text('[ LOG OUT ]'),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<ItemModel> list,
      String empty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          children: list.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(empty,
                        style: const TextStyle(color: AppColors.muted)),
                  )
                ]
              : [
                  for (final i in list)
                    ItemCard(
                      item: i,
                      onTap: () => Navigator.pushNamed(context, '/details',
                          arguments: i.id),
                    )
                ],
        ),
      ),
    );
  }
}
