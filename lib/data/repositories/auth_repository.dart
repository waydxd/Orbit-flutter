import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../../utils/logger.dart';

/// Authentication repository for interacting with Orbit-core auth API
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Extract error message from DioException or other exceptions
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // First, try to extract from response data (backend error format)
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        final errorMsg = data['error'] ?? data['message'];
        if (errorMsg != null && errorMsg is String) {
          return errorMsg;
        }
      }
      // The ApiClient's _processError sets a user-friendly message in error.error
      if (error.error is String) {
        return error.error as String;
      }
      // Fallback to DioException's message property
      if (error.message != null) {
        return error.message!;
      }
      return 'An error occurred';
    }
    return error.toString();
  }

  /// Login with email and password
  /// Returns a tuple of (token, user) on success
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);

        Logger.infoWithTag(
          'AuthRepository',
          'Login successful for user: ${user.email}',
        );
        return {'token': token, 'user': user};
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag('AuthRepository', 'Login failed: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  /// Send registration OTP
  Future<bool> sendRegistrationOTP(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/send-registration-otp',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        Logger.infoWithTag(
          'AuthRepository',
          'Registration OTP sent to: $email',
        );
        return true;
      }
      return false;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag(
        'AuthRepository',
        'Failed to send OTP: $errorMessage',
      );
      throw Exception(errorMessage);
    }
  }

  /// Register a new user with email, password, and OTP
  /// Returns a tuple of (token, user) on success
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String otp,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'otp': otp},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);

        Logger.infoWithTag(
          'AuthRepository',
          'Registration successful for user: ${user.email}',
        );
        return {'token': token, 'user': user};
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag(
        'AuthRepository',
        'Registration failed: $errorMessage',
      );
      throw Exception(errorMessage);
    }
  }

  /// Request password reset (Forgot Password)
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-reset-request',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        Logger.infoWithTag(
          'AuthRepository',
          'Password reset requested for: $email',
        );
        return true;
      }
      return false;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag(
        'AuthRepository',
        'Password reset request failed: $errorMessage',
      );
      throw Exception(errorMessage);
    }
  }

  /// Confirm password reset
  Future<bool> confirmPasswordReset(String token, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-reset-confirm',
        data: {'token': token, 'password': newPassword},
      );

      if (response.statusCode == 200) {
        Logger.infoWithTag(
          'AuthRepository',
          'Password reset successful',
        );
        return true;
      }
      return false;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag(
        'AuthRepository',
        'Password reset confirm failed: $errorMessage',
      );
      throw Exception(errorMessage);
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
      Logger.infoWithTag('AuthRepository', 'Logout successful');
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag('AuthRepository', 'Logout failed: $errorMessage');
      // Don't throw on logout failure - allow logout to proceed even if API call fails
    }
  }

  /// Verify the current authentication token
  Future<bool> verifyToken() async {
    try {
      final response = await _apiClient.post('/auth/verify');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['valid'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      Logger.errorWithTag('AuthRepository', 'Token verification failed: $e');
      return false;
    }
  }

  /// Fetch the authenticated user's profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get('/profile');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }

      throw Exception('Invalid response from server');
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag(
        'AuthRepository',
        'Failed to fetch profile: $errorMessage',
      );
      throw Exception(errorMessage);
    }
  }

  /// Update the authenticated user's profile
  Future<UserModel> updateProfile(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.put('/profile', data: payload);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }

      throw Exception('Invalid response from server');
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.errorWithTag(
        'AuthRepository',
        'Failed to update profile: $errorMessage',
      );
      throw Exception(errorMessage);
    }
  }
}
