import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'report_screen.dart';
import '../viewmodels/items_viewmodel.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavViewModel>();
    final pages = [
      const FeedScreen(),
      const MapScreen(),
      const ReportScreen(),
      const _ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('FINDER'),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: nav.index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.index,
        onDestinationSelected: context.read<NavViewModel>().setIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final items = context.watch<ItemsViewModel>().all;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user?.name ?? 'Account',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(user?.email ?? ''),
          Text(
            'Active posts: ${items.where((item) => item.ownerId == user?.id).length}',
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<NavViewModel>().reset();
              context.read<AuthViewModel>().logout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
