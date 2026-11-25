import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeFirebase();
    runApp(const FinderApp());
  } catch (error) {
    final message =
        error is StateError ? error.message : error.toString();
    runApp(_FirebaseSetupApp(message: message));
  }
}

Future<void> initializeFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    throw StateError(
      'Configure Firebase in lib/firebase_options.dart before starting FINDER on Android.',
    );
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FinderApp extends StatelessWidget {
  const FinderApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService ?? AuthService()),
        ),
        ChangeNotifierProvider(create: (_) => ItemsViewModel(ItemService())),
        ChangeNotifierProvider(create: (_) => NavViewModel()),
      ],
      child: MaterialApp(
        title: 'FINDER',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Consumer<AuthViewModel>(
          builder: (_, auth, __) {
            if (auth.initializing) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return auth.isAuthenticated
                ? const MainShell()
                : const LoginScreen();
          },
        ),
        routes: {
          '/signup': (_) => const SignUpScreen(),
          '/details': (_) => const ItemDetailsScreen(),
        },
      ),
    );
  }
}

class _FirebaseSetupApp extends StatelessWidget {
  const _FirebaseSetupApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINDER',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        appBar: AppBar(title: const Text('FINDER')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Setup Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
