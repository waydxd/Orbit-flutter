import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../config/environment.dart';
import '../../utils/logger.dart';
import 'local_storage_service.dart';

/// HTTP API client for backend communication
class ApiClient {
  late final Dio _dio;
  bool _isRefreshing = false;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${EnvironmentConfig.baseUrl}/api/${AppConfig.apiVersion}',
        connectTimeout: AppConfig.networkTimeout,
        receiveTimeout: AppConfig.networkTimeout,
        sendTimeout: AppConfig.networkTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Logging interceptor for debug mode
    if (EnvironmentConfig.isDebug) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          logPrint: (object) => Logger.debugWithTag('API', object.toString()),
        ),
      );
    }

    // Authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthToken(options);
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _handleTokenRefresh();
            if (refreshed) {
              // Retry the original request with new token
              final newOptions = error.requestOptions;
              await _addAuthToken(newOptions);
              try {
                final response = await _dio.fetch(newOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                // If retry fails, proceed with original error
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    // Error handling interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final processedError = _processError(error);
          handler.next(processedError);
        },
      ),
    );
  }

  /// Add authentication token to request headers
  Future<void> _addAuthToken(RequestOptions options) async {
    final token = await LocalStorageService.getSecure(AppConfig.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Handle token refresh on 401 errors
  Future<bool> _handleTokenRefresh() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return await LocalStorageService.getSecure(AppConfig.accessTokenKey) !=
          null;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await LocalStorageService.getSecure(
        AppConfig.refreshTokenKey,
      );
      if (refreshToken == null) {
        Logger.warningWithTag('API', 'No refresh token available');
        return false;
      }

      // TODO: Replace with actual refresh token API call
      // For now, simulate token refresh
      await Future.delayed(const Duration(seconds: 1));

      // Mock successful refresh - in real implementation, you'd call your refresh endpoint
      const newAccessToken = 'new_mock_access_token';
      await LocalStorageService.storeSecure(
        AppConfig.accessTokenKey,
        newAccessToken,
      );

      Logger.infoWithTag('API', 'Token refreshed successfully');
      return true;
    } catch (e) {
      Logger.errorWithTag('API', 'Token refresh failed: $e');
      // Clear invalid tokens
      await LocalStorageService.deleteSecure(AppConfig.accessTokenKey);
      await LocalStorageService.deleteSecure(AppConfig.refreshTokenKey);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Process and standardize API errors
  DioException _processError(DioException error) {
    final String message;
    final int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        message = _getErrorMessageFromResponse(error.response);
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.badCertificate:
        message = 'Certificate error. Please try again.';
        break;
      case DioExceptionType.unknown:
        message = 'An unexpected error occurred. Please try again.';
        break;
    }

    Logger.errorWithTag(
      'API',
      'Request failed: $message (Status: $statusCode)',
    );

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: message,
    );
  }

  /// Extract error message from response
  String _getErrorMessageFromResponse(Response? response) {
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      return data['message'] ?? data['error'] ?? 'An error occurred';
    }

    switch (response?.statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication failed. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'GET $path failed: ${e.message}');
      rethrow;
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'POST $path failed: ${e.message}');
      rethrow;
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'PUT $path failed: ${e.message}');
      rethrow;
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'PATCH $path failed: ${e.message}');
      rethrow;
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'DELETE $path failed: ${e.message}');
      rethrow;
    }
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
          ...?data,
        }),
        onSendProgress: onSendProgress,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'Upload $path failed: ${e.message}');
      rethrow;
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String path,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: options,
      );
    } on DioException catch (e) {
      Logger.errorWithTag('API', 'Download $path failed: ${e.message}');
      rethrow;
    }
  }

  /// Close the client and cleanup resources
  void close() {
    _dio.close();
  }
}
