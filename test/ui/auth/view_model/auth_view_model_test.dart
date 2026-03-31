import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_calendar/data/repositories/auth_repository.dart';
import 'package:orbit_calendar/data/models/user_model.dart';
import 'package:orbit_calendar/data/services/api_client.dart';
import 'package:orbit_calendar/ui/auth/view_model/auth_view_model.dart';
import 'package:orbit_calendar/utils/validators.dart';
import 'package:orbit_calendar/config/app_config.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(ApiClient());

  int loginCallCount = 0;
  int registerCallCount = 0;
  int sendRegistrationOtpCallCount = 0;
  int requestPasswordResetCallCount = 0;
  int confirmPasswordResetCallCount = 0;
  int logoutCallCount = 0;
  int getProfileCallCount = 0;
  int updateProfileCallCount = 0;
  int verifyTokenCallCount = 0;

  Future<Map<String, dynamic>> Function(String email, String password)?
      loginHandler;
  Future<Map<String, dynamic>> Function(
    String email,
    String password,
    String otp,
  )? registerHandler;
  Future<bool> Function(String email)? sendRegistrationOtpHandler;
  Future<bool> Function(String email)? requestPasswordResetHandler;
  Future<bool> Function(String token, String newPassword)?
      confirmPasswordResetHandler;
  Future<void> Function()? logoutHandler;
  Future<UserModel> Function()? getProfileHandler;
  Future<UserModel> Function(Map<String, dynamic> payload)? updateProfileHandler;
  Future<bool> Function()? verifyTokenHandler;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    loginCallCount++;
    final handler = loginHandler;
    if (handler != null) return handler(email, password);
    return {'token': 'token', 'user': const UserModel(id: 'u1', email: 'u@e')};
  }

  @override
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String otp,
  ) async {
    registerCallCount++;
    final handler = registerHandler;
    if (handler != null) return handler(email, password, otp);
    return {'token': 'token', 'user': UserModel(id: 'u1', email: email)};
  }

  @override
  Future<bool> sendRegistrationOTP(String email) async {
    sendRegistrationOtpCallCount++;
    final handler = sendRegistrationOtpHandler;
    if (handler != null) return handler(email);
    return true;
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    requestPasswordResetCallCount++;
    final handler = requestPasswordResetHandler;
    if (handler != null) return handler(email);
    return true;
  }

  @override
  Future<bool> confirmPasswordReset(String token, String newPassword) async {
    confirmPasswordResetCallCount++;
    final handler = confirmPasswordResetHandler;
    if (handler != null) return handler(token, newPassword);
    return true;
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    final handler = logoutHandler;
    if (handler != null) return handler();
  }

  @override
  Future<UserModel> getProfile() async {
    getProfileCallCount++;
    final handler = getProfileHandler;
    if (handler != null) return handler();
    return const UserModel(id: 'u1', email: 'user@example.com');
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> payload) async {
    updateProfileCallCount++;
    final handler = updateProfileHandler;
    if (handler != null) return handler(payload);
    return const UserModel(id: 'u1', email: 'user@example.com');
  }

  @override
  Future<bool> verifyToken() async {
    verifyTokenCallCount++;
    final handler = verifyTokenHandler;
    if (handler != null) return handler();
    return true;
  }
}

class _FakeAuthLocalStore implements AuthLocalStore {
  final Map<String, String> secure = {};
  final Map<String, dynamic> prefs = {};

  int deleteSecureCallCount = 0;
  int removePreferenceCallCount = 0;

  @override
  Future<void> deleteSecure(String key) async {
    deleteSecureCallCount++;
    secure.remove(key);
  }

  @override
  T? getPreference<T>(String key) {
    return prefs[key] as T?;
  }

  @override
  Future<String?> getSecure(String key) async {
    return secure[key];
  }

  @override
  Future<bool> removePreference(String key) async {
    removePreferenceCallCount++;
    prefs.remove(key);
    return true;
  }

  @override
  Future<bool> setPreference<T>(String key, T value) async {
    prefs[key] = value;
    return true;
  }

  @override
  Future<void> storeSecure(String key, String value) async {
    secure[key] = value;
  }
}

void main() {
  group('AuthViewModel unit tests', () {
    late _FakeAuthRepository fakeRepo;
    late _FakeAuthLocalStore fakeStore;
    late AuthViewModel viewModel;

    const strongPassword = 'Password123!';
    const weakPassword = 'weak';

    setUp(() {
      fakeRepo = _FakeAuthRepository();
      fakeStore = _FakeAuthLocalStore();
      viewModel = AuthViewModel(authRepository: fakeRepo, localStore: fakeStore);
    });

    test('login returns false and sets error for invalid email', () async {
      final result = await viewModel.login('not-an-email', 'Password123!');

      expect(result, isFalse);
      expect(viewModel.error, 'Please enter a valid email address');
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
    });

    test('login returns false and sets error for empty password', () async {
      final result = await viewModel.login('user@example.com', '');

      expect(result, isFalse);
      expect(viewModel.error, 'Please enter your password');
    });

    test('login success sets authenticated state and current user', () async {
      fakeRepo.loginHandler = (email, password) async => {
            'token': 'abc123',
            'user': const UserModel(id: 'u123', email: 'user@example.com'),
          };

      final result = await viewModel.login('user@example.com', strongPassword);

      expect(result, isTrue);
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.currentUser?.id, 'u123');
      expect(viewModel.currentUser?.email, 'user@example.com');
      expect(fakeStore.secure[AppConfig.accessTokenKey], 'abc123');
      expect(fakeStore.prefs['is_authenticated'], isTrue);
      expect(fakeStore.prefs['user_email'], 'user@example.com');
      expect(fakeStore.prefs['user_id'], 'u123');
    });

    test('login failure from repository sets error and clears auth state',
        () async {
      fakeRepo.loginHandler =
          (_, __) async => throw Exception('Invalid credentials');

      final result = await viewModel.login('user@example.com', strongPassword);

      expect(result, isFalse);
      expect(viewModel.error, 'Invalid credentials');
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
    });

    test('register rejects invalid email', () async {
      final result = await viewModel.register(
        'invalid-email',
        strongPassword,
        strongPassword,
        '123456',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Please enter a valid email address');
      expect(fakeRepo.registerCallCount, 0);
    });

    test('register rejects weak password', () async {
      final result = await viewModel.register(
        'user@example.com',
        weakPassword,
        weakPassword,
        '123456',
      );

      expect(result, isFalse);
      expect(viewModel.error, Validators.passwordRequirementError);
      expect(fakeRepo.registerCallCount, 0);
    });

    test('register rejects password mismatch', () async {
      final result = await viewModel.register(
        'user@example.com',
        strongPassword,
        'Different123!',
        '123456',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Passwords do not match');
      expect(fakeRepo.registerCallCount, 0);
    });

    test('register success sets auth state and user', () async {
      fakeRepo.registerHandler = (email, password, otp) async => {
            'token': 'reg-token',
            'user': const UserModel(id: 'u-reg', email: 'user@example.com'),
          };

      final result = await viewModel.register(
        'user@example.com',
        strongPassword,
        strongPassword,
        '123456',
      );

      expect(result, isTrue);
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.currentUser?.id, 'u-reg');
      expect(fakeStore.secure[AppConfig.accessTokenKey], 'reg-token');
    });

    test('register handles repository exception', () async {
      fakeRepo.registerHandler =
          (_, __, ___) async => throw Exception('Email already exists');

      final result = await viewModel.register(
        'user@example.com',
        strongPassword,
        strongPassword,
        '123456',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Email already exists');
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
    });

    test('sendRegistrationOTP validates email before repository call', () async {
      final result = await viewModel.sendRegistrationOTP('invalid-email');

      expect(result, isFalse);
      expect(viewModel.error, 'Please enter a valid email address');
      expect(fakeRepo.sendRegistrationOtpCallCount, 0);
    });

    test('sendRegistrationOTP returns true on successful repository response',
        () async {
      fakeRepo.sendRegistrationOtpHandler = (_) async => true;

      final result = await viewModel.sendRegistrationOTP('user@example.com');

      expect(result, isTrue);
      expect(viewModel.error, isNull);
      expect(fakeRepo.sendRegistrationOtpCallCount, 1);
    });

    test('sendRegistrationOTP surfaces repository exception message', () async {
      fakeRepo.sendRegistrationOtpHandler =
          (_) async => throw Exception('OTP service unavailable');

      final result = await viewModel.sendRegistrationOTP('user@example.com');

      expect(result, isFalse);
      expect(viewModel.error, 'OTP service unavailable');
      expect(fakeRepo.sendRegistrationOtpCallCount, 1);
    });

    test('requestPasswordReset validates email before repository call', () async {
      final result = await viewModel.requestPasswordReset('nope');

      expect(result, isFalse);
      expect(viewModel.error, 'Please enter a valid email address');
      expect(fakeRepo.requestPasswordResetCallCount, 0);
    });

    test('requestPasswordReset returns true on success', () async {
      fakeRepo.requestPasswordResetHandler = (_) async => true;

      final result = await viewModel.requestPasswordReset('user@example.com');

      expect(result, isTrue);
      expect(viewModel.error, isNull);
      expect(fakeRepo.requestPasswordResetCallCount, 1);
    });

    test('confirmPasswordReset validates token length', () async {
      final result = await viewModel.confirmPasswordReset(
        '123',
        'Password123!',
        'Password123!',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Please enter a valid 6-digit reset code');
      expect(fakeRepo.confirmPasswordResetCallCount, 0);
    });

    test('confirmPasswordReset validates weak password', () async {
      final result = await viewModel.confirmPasswordReset(
        '123456',
        weakPassword,
        weakPassword,
      );

      expect(result, isFalse);
      expect(viewModel.error, Validators.passwordRequirementError);
      expect(fakeRepo.confirmPasswordResetCallCount, 0);
    });

    test('confirmPasswordReset validates password match', () async {
      final result = await viewModel.confirmPasswordReset(
        '123456',
        'Password123!',
        'Password456!',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Passwords do not match');
      expect(fakeRepo.confirmPasswordResetCallCount, 0);
    });

    test('confirmPasswordReset returns true on success', () async {
      fakeRepo.confirmPasswordResetHandler = (_, __) async => true;

      final result = await viewModel.confirmPasswordReset(
        '123456',
        'Password123!',
        'Password123!',
      );

      expect(result, isTrue);
      expect(viewModel.error, isNull);
      expect(fakeRepo.confirmPasswordResetCallCount, 1);
    });

    test('confirmPasswordReset handles repository exception', () async {
      fakeRepo.confirmPasswordResetHandler =
          (_, __) async => throw Exception('Reset token expired');

      final result = await viewModel.confirmPasswordReset(
        '123456',
        strongPassword,
        strongPassword,
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Reset token expired');
      expect(fakeRepo.confirmPasswordResetCallCount, 1);
    });

    test('logout clears auth state even when API fails', () async {
      await viewModel.login('user@example.com', strongPassword);
      fakeRepo.logoutHandler = () async => throw Exception('Network error');

      await viewModel.logout();

      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(fakeRepo.logoutCallCount, 1);
      expect(fakeStore.secure[AppConfig.accessTokenKey], isNull);
      expect(fakeStore.prefs['is_authenticated'], isNull);
      expect(fakeStore.prefs['user_email'], isNull);
      expect(fakeStore.prefs['user_id'], isNull);
    });

    test('loadProfile returns false when not authenticated', () async {
      final result = await viewModel.loadProfile();

      expect(result, isFalse);
      expect(viewModel.error, 'Please login again to view your profile');
      expect(fakeRepo.getProfileCallCount, 0);
    });

    test('loadProfile success updates current user', () async {
      await viewModel.login('user@example.com', strongPassword);
      fakeRepo.getProfileHandler = () async => const UserModel(
            id: 'profile-id',
            email: 'profile@example.com',
            firstName: 'Orbit',
          );

      final result = await viewModel.loadProfile();

      expect(result, isTrue);
      expect(viewModel.currentUser?.id, 'profile-id');
      expect(viewModel.currentUser?.email, 'profile@example.com');
      expect(fakeStore.prefs['user_email'], 'profile@example.com');
      expect(fakeStore.prefs['user_id'], 'profile-id');
    });

    test('updateProfile returns false when not authenticated', () async {
      final result = await viewModel.updateProfile(
        firstName: 'A',
        lastName: 'B',
        username: 'user_name',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Please login again to update your profile');
      expect(fakeRepo.updateProfileCallCount, 0);
    });

    test('updateProfile success updates current user', () async {
      await viewModel.login('user@example.com', strongPassword);
      fakeRepo.updateProfileHandler = (payload) async => const UserModel(
            id: 'updated-id',
            email: 'updated@example.com',
            firstName: 'Updated',
          );

      final result = await viewModel.updateProfile(
        firstName: 'Updated',
        lastName: 'User',
        username: 'updated_user',
        region: 'Europe',
        timezone: 'CET',
        gender: 'male',
      );

      expect(result, isTrue);
      expect(viewModel.currentUser?.id, 'updated-id');
      expect(viewModel.currentUser?.email, 'updated@example.com');
      expect(fakeStore.prefs['user_email'], 'updated@example.com');
      expect(fakeStore.prefs['user_id'], 'updated-id');
    });

    test('completeRegistration rejects short username', () async {
      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'ab',
        password: strongPassword,
        confirmPassword: strongPassword,
        firstName: 'A',
        lastName: 'B',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('Username must be 3-50 characters'));
    });

    test('completeRegistration rejects invalid username chars', () async {
      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'bad name!',
        password: strongPassword,
        confirmPassword: strongPassword,
        firstName: 'A',
        lastName: 'B',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('Username must be 3-50 characters'));
    });

    test('completeRegistration rejects consecutive underscore', () async {
      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'user__name',
        password: strongPassword,
        confirmPassword: strongPassword,
        firstName: 'A',
        lastName: 'B',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('Username must be 3-50 characters'));
    });

    test('completeRegistration rejects weak password', () async {
      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'valid_user',
        password: weakPassword,
        confirmPassword: weakPassword,
        firstName: 'A',
        lastName: 'B',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, Validators.passwordRequirementError);
    });

    test('completeRegistration rejects password mismatch', () async {
      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'valid_user',
        password: strongPassword,
        confirmPassword: 'Different123!',
        firstName: 'A',
        lastName: 'B',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Passwords do not match');
    });

    test('completeRegistration success path', () async {
      fakeRepo.registerHandler = (email, password, otp) async => {
            'token': 'comp-token',
            'user': const UserModel(id: 'u-complete', email: 'user@example.com'),
          };
      fakeRepo.updateProfileHandler = (payload) async => const UserModel(
            id: 'u-complete',
            email: 'user@example.com',
            firstName: 'First',
            lastName: 'Last',
          );

      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'valid_user',
        password: strongPassword,
        confirmPassword: strongPassword,
        firstName: 'First',
        lastName: 'Last',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isTrue);
      expect(viewModel.currentUser?.id, 'u-complete');
      expect(viewModel.currentUser?.email, 'user@example.com');
      expect(fakeRepo.registerCallCount, 1);
      expect(fakeRepo.updateProfileCallCount, 1);
    });

    test('completeRegistration handles repository exception', () async {
      fakeRepo.registerHandler =
          (_, __, ___) async => throw Exception('Registration backend failed');

      final result = await viewModel.completeRegistration(
        email: 'user@example.com',
        username: 'valid_user',
        password: strongPassword,
        confirmPassword: strongPassword,
        firstName: 'First',
        lastName: 'Last',
        region: 'Asia',
        timezone: 'UTC',
        gender: 'female',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Registration backend failed');
    });

    test('checkAuthStatus keeps user logged out when preference is false',
        () async {
      fakeStore.prefs['is_authenticated'] = false;

      await viewModel.checkAuthStatus();

      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(fakeRepo.verifyTokenCallCount, 0);
    });

    test('checkAuthStatus clears invalid stored auth data', () async {
      fakeStore.prefs['is_authenticated'] = true;
      fakeStore.prefs['user_email'] = 'user@example.com';
      // Missing token and user_id.

      await viewModel.checkAuthStatus();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(fakeStore.prefs['is_authenticated'], isNull);
      expect(fakeStore.prefs['user_email'], isNull);
    });

    test('checkAuthStatus authenticates when token and profile keys are valid',
        () async {
      fakeStore.prefs['is_authenticated'] = true;
      fakeStore.prefs['user_email'] = 'user@example.com';
      fakeStore.prefs['user_id'] = 'u-valid';
      fakeStore.secure[AppConfig.accessTokenKey] = 'valid-token';
      fakeRepo.verifyTokenHandler = () async => true;

      await viewModel.checkAuthStatus();

      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.currentUser?.id, 'u-valid');
      expect(viewModel.currentUser?.email, 'user@example.com');
      expect(fakeRepo.verifyTokenCallCount, 1);
    });

    test('checkAuthStatus clears auth when token verification fails', () async {
      fakeStore.prefs['is_authenticated'] = true;
      fakeStore.prefs['user_email'] = 'user@example.com';
      fakeStore.prefs['user_id'] = 'u-valid';
      fakeStore.secure[AppConfig.accessTokenKey] = 'invalid-token';
      fakeRepo.verifyTokenHandler = () async => false;

      await viewModel.checkAuthStatus();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(fakeStore.prefs['is_authenticated'], isNull);
    });
  });
}
