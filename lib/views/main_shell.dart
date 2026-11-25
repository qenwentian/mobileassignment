import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';
import 'admin/admin_screen.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavViewModel>();
    // The Admin tab only exists for admins, so non-admins never build it
    // (and never open the admin-only Firestore listeners).
    final isAdmin = context.watch<AuthViewModel>().isAdmin;
    final pages = [
      const FeedScreen(),
      const MapScreen(),
      const ReportScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminScreen(),
    ];
    // If the role changes while the Admin tab is open, fall back to Feed.
    final index = nav.index < pages.length ? nav.index : 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FINDER'),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: context.read<NavViewModel>().setIndex,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            label: 'Report',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
