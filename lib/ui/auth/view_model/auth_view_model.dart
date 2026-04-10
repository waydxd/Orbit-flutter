import 'dart:async';

import '../../core/view_models/base_view_model.dart';
import '../../../core/services/fcm_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_token_service.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../config/app_config.dart';
import '../../../utils/logger.dart';
import '../../../utils/validators.dart';

/// Authentication state management
class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;
  bool _isAuthenticated = false;
  UserModel? _currentUser;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(ApiClient());

  /// Authentication state
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  String? get currentUserEmail => _currentUser?.email;
  String? get currentUserDisplayName => _currentUser?.displayName;

  Future<void> _persistAuthenticatedSession(
    String token,
    UserModel user,
  ) async {
    _isAuthenticated = true;
    _currentUser = user;

    await LocalStorageService.storeSecure(AppConfig.accessTokenKey, token);
    await LocalStorageService.setPreference('is_authenticated', true);
    await LocalStorageService.setPreference('user_email', user.email);
    await LocalStorageService.setPreference('user_id', user.id);
  }

  String _extractErrorMessage(dynamic error, String fallbackMessage) {
    if (error is Exception) {
      return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    }
    final message = error.toString();
    return message.isEmpty ? fallbackMessage : message;
  }

  /// FCM token registration must not block or fail auth; runs after session is stored.
  void _scheduleFcmTokenRegistration() {
    unawaited(
      FcmService()
          .registerTokenWithBackend()
          .catchError((Object e, StackTrace st) {
        Logger.debugWithTag('FCM', 'Background token registration failed: $e');
      }),
    );
  }

  bool _isValidUsername(String username) {
    if (username.length < 3 || username.length > 50) return false;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(username)) return false;
    if (RegExp(r'[_-]{2,}').hasMatch(username)) return false;
    return true;
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    // Validate inputs
    if (!Validators.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }

    if (password.isEmpty) {
      setError('Please enter your password');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            final result = await _authRepository.login(email, password);
            final token = result['token'] as String;
            final user = result['user'] as UserModel;
            await _persistAuthenticatedSession(token, user);
            _scheduleFcmTokenRegistration();

            return true;
          } catch (e) {
            _isAuthenticated = false;
            _currentUser = null;
            setError(
                _extractErrorMessage(e, 'Login failed. Please try again.'));
            return false;
          }
        }) ??
        false;
  }

  /// Send registration OTP
  Future<bool> sendRegistrationOTP(String email) async {
    // Validate inputs
    if (!Validators.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            return await _authRepository.sendRegistrationOTP(email);
          } catch (e) {
            String errorMessage = 'Failed to send OTP. Please try again.';
            if (e is Exception) {
              final message = e.toString();
              errorMessage = message.replaceFirst(
                RegExp(r'^Exception:\s*'),
                '',
              );
            } else {
              errorMessage = e.toString();
            }
            setError(errorMessage);
            return false;
          }
        }) ??
        false;
  }

  /// Register new user
  Future<bool> register(
    String email,
    String password,
    String confirmPassword,
    String otp,
  ) async {
    // Validate inputs
    if (!Validators.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }

    if (!Validators.isValidPassword(password)) {
      setError(Validators.passwordRequirementError);
      return false;
    }

    if (password != confirmPassword) {
      setError('Passwords do not match');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            final result = await _authRepository.register(email, password, otp);
            final token = result['token'] as String;
            final user = result['user'] as UserModel;
            await _persistAuthenticatedSession(token, user);
            _scheduleFcmTokenRegistration();

            return true;
          } catch (e) {
            _isAuthenticated = false;
            _currentUser = null;
            setError(
              _extractErrorMessage(e, 'Registration failed. Please try again.'),
            );
            return false;
          }
        }) ??
        false;
  }

  Future<bool> completeRegistration({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String region,
    required String timezone,
    required String gender,
    DateTime? birthDate,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedUsername = username.trim();

    if (!Validators.isValidEmail(trimmedEmail)) {
      setError('Please enter a valid email address');
      return false;
    }

    if (!_isValidUsername(trimmedUsername)) {
      setError(
        'Username must be 3-50 characters and use only letters, numbers, underscores, and hyphens',
      );
      return false;
    }

    if (!Validators.isValidPassword(password)) {
      setError(Validators.passwordRequirementError);
      return false;
    }

    if (password != confirmPassword) {
      setError('Passwords do not match');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            final shouldRegister =
                !(_isAuthenticated && _currentUser?.email == trimmedEmail);

            if (shouldRegister) {
              final result = await _authRepository.register(
                trimmedEmail,
                password,
                '',
              );
              final token = result['token'] as String;
              final user = result['user'] as UserModel;
              await _persistAuthenticatedSession(token, user);
            }

            final payload = <String, dynamic>{
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'username': trimmedUsername,
              'region': region.trim(),
              'timezone': timezone.trim(),
              'gender': gender.trim(),
              'birth_date': birthDate == null
                  ? ''
                  : '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
            };

            final profile = await _authRepository.updateProfile(payload);
            _currentUser = profile;
            await LocalStorageService.setPreference(
                'user_email', profile.email);
            await LocalStorageService.setPreference('user_id', profile.id);
            _scheduleFcmTokenRegistration();
            return true;
          } catch (e) {
            setError(
              _extractErrorMessage(
                e,
                'Registration failed. Please try again.',
              ),
            );
            return false;
          }
        }) ??
        false;
  }

  /// Request Password Reset
  Future<bool> requestPasswordReset(String email) async {
    if (!Validators.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            return await _authRepository.requestPasswordReset(email);
          } catch (e) {
            String errorMessage = 'Failed to request password reset.';
            if (e is Exception) {
              errorMessage =
                  e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
            } else {
              errorMessage = e.toString();
            }
            setError(errorMessage);
            return false;
          }
        }) ??
        false;
  }

  /// Confirm Password Reset
  Future<bool> confirmPasswordReset(
      String token, String newPassword, String confirmPassword) async {
    if (token.isEmpty || token.length != 6) {
      setError('Please enter a valid 6-digit reset code');
      return false;
    }

    if (!Validators.isValidPassword(newPassword)) {
      setError(Validators.passwordRequirementError);
      return false;
    }

    if (newPassword != confirmPassword) {
      setError('Passwords do not match');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            return await _authRepository.confirmPasswordReset(
                token, newPassword);
          } catch (e) {
            String errorMessage = 'Failed to reset password.';
            if (e is Exception) {
              errorMessage =
                  e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
            } else {
              errorMessage = e.toString();
            }
            setError(errorMessage);
            return false;
          }
        }) ??
        false;
  }

  /// Logout user
  Future<void> logout() async {
    await executeAsync(() async {
      try {
        // Call logout API to invalidate session on server
        await _authRepository.logout();
      } catch (e) {
        // Even if logout API fails, clear local state
        // This ensures user can still logout if there's a network issue
      }
      try {
        // Requires JWT; must run before clearing tokens
        await FcmService().unregisterToken();
      } catch (e) {
        // Best-effort: proceed with local logout
      }
      _isAuthenticated = false;
      _currentUser = null;

      await LocalStorageService.deleteSecure(AppConfig.accessTokenKey);
      await LocalStorageService.deleteSecure(AppConfig.refreshTokenKey);
      await LocalStorageService.removePreference('is_authenticated');
      await LocalStorageService.removePreference('user_email');
      await LocalStorageService.removePreference('user_id');
    }, showLoading: false);
  }

  Future<bool> loadProfile() async {
    if (!_isAuthenticated && _currentUser == null) {
      setError('Please login again to view your profile');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            final profile = await _authRepository.getProfile();
            _currentUser = profile;
            await LocalStorageService.setPreference(
                'user_email', profile.email);
            await LocalStorageService.setPreference('user_id', profile.id);
            return true;
          } catch (e) {
            String errorMessage = 'Failed to load profile.';
            if (e is Exception) {
              errorMessage =
                  e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
            } else {
              errorMessage = e.toString();
            }
            setError(errorMessage);
            return false;
          }
        }, showLoading: true) ??
        false;
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String region,
    required String timezone,
    required String gender,
    DateTime? birthDate,
  }) async {
    if (!_isAuthenticated && _currentUser == null) {
      setError('Please login again to update your profile');
      return false;
    }

    return await executeAsync<bool>(() async {
          try {
            final payload = <String, dynamic>{
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'username': username.trim(),
              'region': region.trim(),
              'timezone': timezone.trim(),
              'gender': gender.trim(),
              'birth_date': birthDate == null
                  ? ''
                  : '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
            };

            final profile = await _authRepository.updateProfile(payload);
            _currentUser = profile;
            await LocalStorageService.setPreference(
                'user_email', profile.email);
            await LocalStorageService.setPreference('user_id', profile.id);
            return true;
          } catch (e) {
            String errorMessage = 'Failed to update profile.';
            if (e is Exception) {
              errorMessage =
                  e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
            } else {
              errorMessage = e.toString();
            }
            setError(errorMessage);
            return false;
          }
        }) ??
        false;
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    // Use executeAsync but with showLoading false to avoid blocking UI
    await executeAsync(() async {
      try {
        // Quick check: if no stored auth preference, skip everything
        bool isAuth = false;
        try {
          isAuth =
              LocalStorageService.getPreference<bool>('is_authenticated') ??
                  false;
        } catch (e) {
          // If we can't read preferences, assume not authenticated
          _isAuthenticated = false;
          _currentUser = null;
          return;
        }

        if (!isAuth) {
          _isAuthenticated = false;
          _currentUser = null;
          return;
        }

        // If we have a stored preference, check for token and user data
        String? token;
        String? email;
        String? userId;

        try {
          token = await AuthTokenService.getAccessToken();
          email = LocalStorageService.getPreference<String>('user_email');
          userId = LocalStorageService.getPreference<String>('user_id');
        } catch (e) {
          // If we can't read storage, assume not authenticated
          _isAuthenticated = false;
          _currentUser = null;
          return;
        }

        // If we don't have all required data, clear everything and exit
        if (token == null || email == null || userId == null) {
          _isAuthenticated = false;
          _currentUser = null;
          // Clear invalid data asynchronously to avoid blocking
          Future.microtask(() async {
            await LocalStorageService.deleteSecure(AppConfig.accessTokenKey);
            await LocalStorageService.removePreference('is_authenticated');
            await LocalStorageService.removePreference('user_email');
            await LocalStorageService.removePreference('user_id');
          });
          return;
        }

        // We have all data, verify token is still valid
        // Use a very short timeout to avoid hanging if server is down
        try {
          final isValid = await _authRepository.verifyToken().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              // If verification times out, assume token is invalid
              // This is fine - user can login again
              return false;
            },
          );

          if (isValid) {
            _isAuthenticated = true;
            _currentUser = UserModel(id: userId, email: email);
            unawaited(
              FcmService()
                  .registerTokenWithBackend()
                  .catchError((Object e, StackTrace st) {
                Logger.debugWithTag(
                  'FCM',
                  'Token registration after session restore failed: $e',
                );
              }),
            );
          } else {
            // Token is invalid, clear authentication state
            _isAuthenticated = false;
            _currentUser = null;
            // Clear invalid data asynchronously
            Future.microtask(() async {
              await LocalStorageService.deleteSecure(AppConfig.accessTokenKey);
              await LocalStorageService.removePreference('is_authenticated');
              await LocalStorageService.removePreference('user_email');
              await LocalStorageService.removePreference('user_id');
            });
          }
        } catch (e) {
          // If verification fails for any reason, clear auth state
          // This is expected if backend is not running
          _isAuthenticated = false;
          _currentUser = null;
          // Clear invalid data asynchronously
          Future.microtask(() async {
            await LocalStorageService.deleteSecure(AppConfig.accessTokenKey);
            await LocalStorageService.removePreference('is_authenticated');
            await LocalStorageService.removePreference('user_email');
            await LocalStorageService.removePreference('user_id');
          });
        }
      } catch (e) {
        // If anything goes wrong, ensure we're not authenticated
        _isAuthenticated = false;
        _currentUser = null;
      }
    }, showLoading: false);
  }
}
