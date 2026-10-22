import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/item_service.dart';
import 'theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/items_viewmodel.dart';
import 'viewmodels/nav_viewmodel.dart';
import 'views/item_details_screen.dart';
import 'views/login_screen.dart';
import 'views/main_shell.dart';
import 'views/signup_screen.dart';

void main() => runApp(const FinderApp());

class FinderApp extends StatelessWidget {
  const FinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthService())),
        ChangeNotifierProvider(create: (_) => ItemsViewModel(ItemService())),
        ChangeNotifierProvider(create: (_) => NavViewModel()),
      ],
      child: MaterialApp(
        title: 'FINDER',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Consumer<AuthViewModel>(
          builder: (_, auth, __) =>
              auth.isAuthenticated ? const MainShell() : const LoginScreen(),
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/details': (_) => const ItemDetailsScreen(),
        },
      ),
    );
  }
}
