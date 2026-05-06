import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/search_cubit.dart';
import 'routes/app_router.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<NotificationService> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrapNotifications(
      NotificationService notificationService) async {
    try {
      await notificationService.initialize();
      await notificationService.subscribeToGeneralTopics();
    } catch (error) {
      debugPrint('Notification bootstrap failed: $error');
    }
  }

  Future<NotificationService> _bootstrap() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    final NotificationService notificationService = NotificationService();
    unawaited(_bootstrapNotifications(notificationService));
    return notificationService;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationService>(
      future: _bootstrapFuture,
      builder:
          (BuildContext context, AsyncSnapshot<NotificationService> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            home: const _BootstrapLoadingScreen(),
          );
        }

        if (snapshot.hasError) {
          return BootstrapErrorApp(message: snapshot.error.toString());
        }

        return CampusConnectApp(notificationService: snapshot.data!);
      },
    );
  }
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<NavProvider>(create: (_) => NavProvider()),
        ChangeNotifierProvider<FeedProvider>(create: (_) => FeedProvider()),
        ChangeNotifierProxyProvider2<AuthService, FirestoreService,
            AuthProvider>(
          create: (BuildContext context) => AuthProvider(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
          update: (BuildContext context, AuthService auth,
              FirestoreService firestore, AuthProvider? previous) {
            return previous ?? AuthProvider(auth, firestore);
          },
        ),
      ],
      child: BlocProvider<SearchCubit>(
        create: (_) => SearchCubit(),
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (BuildContext context, Widget? child) {
            return StreamBuilder<List<ConnectivityResult>>(
              // Remove 'await' here. The stream is a property, not a future.
              stream: Connectivity().onConnectivityChanged,
              initialData: const [ConnectivityResult.wifi],
              builder: (context, snapshot) {
                // Get the list, default to empty if null
                final results = snapshot.data ?? [];

                // If the list is empty or contains 'none', we are offline
                final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);

                final content = child ?? const SizedBox.shrink();

                if (isOffline) {
                  return OfflineBannerShell(child: content);
                }

                return content;
              },
            );
          },
          home: const RootGate(),
        ),
      ),
    );
  }
}

/// Chooses the first visible route from auth readiness and verification state.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    if (!authProvider.isReady) {
      return const _BootstrapLoadingScreen();
    }

    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    if (!authProvider.isEmailVerified) {
      return const EmailVerificationScreen();
    }

    return const HomeShellScreen();
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Starting CampusConnect...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'CampusConnect could not start.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
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
