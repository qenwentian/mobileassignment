import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';
import 'feed_screen.dart';
import 'report_screen.dart';
import '../viewmodels/items_viewmodel.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavViewModel>();
    final pages = [
      const FeedScreen(),
      const _MapScreen(),
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

class _MapScreen extends StatelessWidget {
  const _MapScreen();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemsViewModel>();
    final nav = context.watch<NavViewModel>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Campus locations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Map directions are a demo view of campus pins.'),
        for (final pin in vm.pins)
          Card(
            child: ListTile(
              leading: Icon(
                nav.selectedPinId == pin.id
                    ? Icons.location_on
                    : Icons.place,
                color: AppColors.accent,
              ),
              title: Text(pin.id),
              subtitle: Text(pin.room),
            ),
          ),
      ],
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
              context.read<AuthViewModel>().logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (r) => false);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
