import '../../core/view_models/base_view_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../config/app_config.dart';
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

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    // Validate inputs
    if (!Validators.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }
    
    if (!Validators.isValidPassword(password)) {
      setError('Password must be at least 8 characters long');
      return false;
    }

    return await executeAsync<bool>(
      () async {
        try {
          final result = await _authRepository.login(email, password);
          final token = result['token'] as String;
          final user = result['user'] as UserModel;

          _isAuthenticated = true;
          _currentUser = user;

          // Store authentication state
          await LocalStorageService.storeSecure(
            AppConfig.accessTokenKey,
            token,
          );
          await LocalStorageService.setPreference('is_authenticated', true);
          await LocalStorageService.setPreference('user_email', user.email);
          await LocalStorageService.setPreference('user_id', user.id);

          return true;
        } catch (e) {
          _isAuthenticated = false;
          _currentUser = null;
          
          // Extract error message from exception
          String errorMessage = 'Login failed. Please try again.';
          if (e is Exception) {
            final message = e.toString();
            // Remove "Exception: " prefix if present
            errorMessage = message.replaceFirst(RegExp(r'^Exception:\s*'), '');
          } else {
            errorMessage = e.toString();
          }
          
          setError(errorMessage);
          return false;
        }
      },
    ) ?? false;
  }

  /// Register new user
  Future<bool> register(String email, String password, String confirmPassword) async {
    // Validate inputs
    if (!Validators.isValidEmail(email)) {
      setError('Please enter a valid email address');
      return false;
    }
    
    if (!Validators.isValidPassword(password)) {
      setError('Password must be at least 8 characters long');
      return false;
    }
    
    if (password != confirmPassword) {
      setError('Passwords do not match');
      return false;
    }

    return await executeAsync<bool>(
      () async {
        try {
          final result = await _authRepository.register(email, password);
          final token = result['token'] as String;
          final user = result['user'] as UserModel;

          _isAuthenticated = true;
          _currentUser = user;

          // Store authentication state
          await LocalStorageService.storeSecure(
            AppConfig.accessTokenKey,
            token,
          );
          await LocalStorageService.setPreference('is_authenticated', true);
          await LocalStorageService.setPreference('user_email', user.email);
          await LocalStorageService.setPreference('user_id', user.id);

          return true;
        } catch (e) {
          _isAuthenticated = false;
          _currentUser = null;
          
          // Extract error message from exception
          String errorMessage = 'Registration failed. Please try again.';
          if (e is Exception) {
            final message = e.toString();
            // Remove "Exception: " prefix if present
            errorMessage = message.replaceFirst(RegExp(r'^Exception:\s*'), '');
          } else {
            errorMessage = e.toString();
          }
          
          setError(errorMessage);
          return false;
        }
      },
    ) ?? false;
  }

  /// Logout user
  Future<void> logout() async {
    await executeAsync(
      () async {
        try {
          // Call logout API to invalidate session on server
          await _authRepository.logout();
        } catch (e) {
          // Even if logout API fails, clear local state
          // This ensures user can still logout if there's a network issue
        } finally {
          _isAuthenticated = false;
          _currentUser = null;

          // Clear stored authentication data
          await LocalStorageService.deleteSecure(AppConfig.accessTokenKey);
          await LocalStorageService.deleteSecure(AppConfig.refreshTokenKey);
          await LocalStorageService.removePreference('is_authenticated');
          await LocalStorageService.removePreference('user_email');
          await LocalStorageService.removePreference('user_id');
        }
      },
      showLoading: false,
    );
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    // Use executeAsync but with showLoading false to avoid blocking UI
    await executeAsync(
      () async {
        try {
          // Quick check: if no stored auth preference, skip everything
          bool isAuth = false;
          try {
            isAuth = LocalStorageService.getPreference<bool>('is_authenticated') ?? false;
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
            token = await LocalStorageService.getSecure(AppConfig.accessTokenKey);
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
            final isValid = await _authRepository.verifyToken()
                .timeout(
                  const Duration(seconds: 3),
                  onTimeout: () {
                    // If verification times out, assume token is invalid
                    // This is fine - user can login again
                    return false;
                  },
                );
            
            if (isValid) {
              _isAuthenticated = true;
              _currentUser = UserModel(
                id: userId,
                email: email,
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
      },
      showLoading: false,
    );
  }
}
