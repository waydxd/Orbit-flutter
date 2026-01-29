import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/core/themes/app_theme.dart';
import 'config/app_config.dart';
import 'ui/auth/view_model/auth_view_model.dart';
import 'ui/calendar/view_model/calendar_view_model.dart';
import 'data/view_models/suggestions_view_model.dart';
import 'ui/auth/view/login_page.dart';
import 'utils/constants.dart';

import 'ui/calendar/view/calendar_page.dart';

/// Main application widget
class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => SuggestionsViewModel()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper that handles authentication state and navigation
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    // Schedule auth initialization after the first frame to avoid creating
    // timers (e.g. Future.delayed) which can leave pending timers in widget
    // tests. Using addPostFrameCallback does not create a test timer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    // Note: previous implementation used a small Future.delayed to ensure the
    // widget was built; using addPostFrameCallback above serves the same
    // purpose without creating timers that persist in tests.

    if (!mounted) return;

    try {
      // Check authentication status with a timeout
      await Provider.of<AuthViewModel>(
        context,
        listen: false,
      ).checkAuthStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // If check takes too long, just proceed without authentication
          debugPrint('Auth check timed out, proceeding to login');
          return;
        },
      );
    } catch (e) {
      // If check fails, proceed without authentication
      debugPrint('Auth check failed: $e');
    } finally {
      // Always set the flag to true to proceed to login page
      if (mounted) {
        setState(() {
          _isInitialCheckComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        // Show splash screen only during initial check
        // Don't wait for loading state to avoid hanging
        if (!_isInitialCheckComplete) {
          return const SplashScreen();
        }

        // Navigate based on authentication state
        if (authViewModel.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Constants.spacingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: Constants.splashIconSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: Constants.spacingL),
                Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: Constants.fontWeightBold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Constants.spacingS),
                Text(
                  'Intelligent Calendar & Planning',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: Constants.opacityHigh,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Constants.spacingXXL),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder home screen - Replaced with CalendarPage
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalendarPage();
  }
}
