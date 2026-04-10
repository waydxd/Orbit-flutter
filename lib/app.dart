import 'dart:async';

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
  static const Duration _minimumSplashDuration = Duration(seconds: 2);

  Timer? _minimumSplashTimer;
  Completer<void>? _minimumSplashWaitCompleter;

  @override
  void initState() {
    super.initState();
    // Schedule auth after first frame. Minimum splash uses a Timer that is
    // cancelled in dispose so widget tests do not end with a pending timer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  @override
  void dispose() {
    _minimumSplashTimer?.cancel();
    _minimumSplashTimer = null;
    final wait = _minimumSplashWaitCompleter;
    _minimumSplashWaitCompleter = null;
    if (wait != null && !wait.isCompleted) {
      wait.complete();
    }
    super.dispose();
  }

  Future<void> _waitRemainingMinimumSplash(Duration remaining) async {
    if (remaining <= Duration.zero) return;
    final completer = Completer<void>();
    _minimumSplashWaitCompleter = completer;
    _minimumSplashTimer = Timer(remaining, () {
      _minimumSplashTimer = null;
      _minimumSplashWaitCompleter = null;
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  Future<void> _initializeAuth() async {
    if (!mounted) return;

    final startedAt = DateTime.now();

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
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = _minimumSplashDuration - elapsed;
      await _waitRemainingMinimumSplash(remaining);

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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
                      duration: _AuthWrapperState._minimumSplashDuration,
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
