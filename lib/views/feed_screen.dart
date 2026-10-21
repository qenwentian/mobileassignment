import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../viewmodels/items_viewmodel.dart';
import 'widgets/item_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemsViewModel>();
    final items = vm.filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campus Lost & Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: vm.setQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppColors.muted),
              hintText: 'Search items nearby...',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in ItemsViewModel.filterCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: vm.category == c,
                      onSelected: (_) => vm.setCategory(c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No items match. Try another search or category.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => ItemCard(
                      item: items[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/details',
                        arguments: items[i].id,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
