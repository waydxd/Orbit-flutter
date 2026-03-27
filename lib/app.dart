import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/view/main_navigation_shell.dart';
import 'ui/core/widgets/orbit_animation.dart';
import 'config/app_config.dart';
import 'ui/auth/view_model/auth_view_model.dart';
import 'ui/calendar/view_model/calendar_view_model.dart';
import 'ui/auth/view/login_page.dart';
import 'utils/constants.dart';

/// Main application widget
class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
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
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final calendarViewModel = Provider.of<CalendarViewModel>(
        context,
        listen: false,
      );

      // Check authentication status with a timeout
      await authViewModel.checkAuthStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // If check takes too long, just proceed without authentication
          debugPrint('Auth check timed out, proceeding to login');
          return;
        },
      );

      // Keep splash visible until initial calendar/task data is loaded.
      if (authViewModel.isAuthenticated) {
        final userId = authViewModel.currentUser?.id;
        if (userId != null) {
          await calendarViewModel.fetchAll(userId: userId).timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('Initial data preload timed out, continuing app');
            },
          );
        }
      }
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
          return const MainNavigationShell();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Constants.spacingM),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OrbitAnimation(
                      width: Constants.splashIconSize * 1.8,
                      height: Constants.splashIconSize * 1.8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
