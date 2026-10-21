import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/items_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';
import 'widgets/item_card.dart';

class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! String) {
      return const Scaffold(
        body: Center(child: Text('Item details are unavailable.')),
      );
    }
    final id = args;
    final vm = context.watch<ItemsViewModel>();
    final item = vm.byId(id);
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Item not found')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    height: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.hasPhoto
                              ? Icons.image_outlined
                              : Icons.hide_image_outlined,
                          size: 48,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.hasPhoto
                              ? 'Demo photo placeholder (no image attached)'
                              : 'No photo provided',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      StatusTag(item.status),
                      if (item.isClaimed) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Claim pending',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _row(Icons.category_outlined, 'Category', item.category),
                  _row(Icons.place_outlined, 'Location', item.locationDetail),
                  _row(
                    Icons.schedule,
                    'Posted',
                    '${item.preciseTime} (${item.timeAgo})',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(item.description),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.accent),
                      ),
                      onPressed: () {
                        // Pre-highlight this item's building, then show the Map tab.
                        context.read<NavViewModel>().focusItemOnMap(item);
                        Navigator.pop(context);
                      },
                      child: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: item.isClaimed
                          ? null
                          : () {
                              final user = context.read<AuthViewModel>().user;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Log in to claim an item.'),
                                  ),
                                );
                                return;
                              }
                              final err = vm.claim(item.id, user);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    err ??
                                        'Claim sent. Security will verify your ownership.',
                                  ),
                                ),
                              );
                            },
                      child: Text(item.isClaimed ? 'Claim Sent' : 'Claim Item'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
