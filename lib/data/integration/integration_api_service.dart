import 'package:dio/dio.dart';

import '../services/api_client.dart';
import 'integration_validators.dart';

/// Typed, validated calls to `/api/v1/integration/*`.
///
/// Use this instead of raw [ApiClient] for integration routes so payloads match OpenAPI.
class IntegrationApiService {
  IntegrationApiService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  void _throwIfInvalid(String? error) {
    if (error != null) throw IntegrationValidationException(error);
  }

  /// POST /integration/sync
  Future<Response<T>> postSync<T>({
    required String source,
    required String target,
    Map<String, dynamic>? data,
  }) async {
    _throwIfInvalid(IntegrationValidators.validateSyncRequest(
      source: source,
      target: target,
    ));
    return _api.post<T>(
      '/integration/sync',
      data: {
        'source': source,
        'target': target,
        if (data != null) 'data': data,
      },
    );
  }

  /// POST /integration/webhooks
  Future<Response<T>> postWebhook<T>(Map<String, dynamic> body) async {
    _throwIfInvalid(IntegrationValidators.validateWebhookPayload(body));
    return _api.post<T>('/integration/webhooks', data: body);
  }

  /// POST /integration/external/connect
  Future<Response<T>> postExternalConnect<T>({
    required String service,
    required String apiKey,
  }) async {
    _throwIfInvalid(IntegrationValidators.validateExternalConnect(
      service: service,
      apiKey: apiKey,
    ));
    return _api.post<T>(
      '/integration/external/connect',
      data: {'service': service, 'api_key': apiKey},
    );
  }

  /// POST /integration/external/disconnect
  Future<Response<T>> postExternalDisconnect<T>(
      {required String service}) async {
    _throwIfInvalid(
        IntegrationValidators.validateExternalDisconnect(service: service));
    return _api.post<T>(
      '/integration/external/disconnect',
      data: {'service': service},
    );
  }

  /// GET /integration/external/status
  Future<Response<T>> getExternalStatus<T>() =>
      _api.get<T>('/integration/external/status');

  /// GET /integration/export
  Future<Response<T>> getExport<T>({
    required String format,
    String? startTime,
    String? endTime,
    Options? options,
  }) async {
    _throwIfInvalid(IntegrationValidators.validateExportFormat(format));
    _throwIfInvalid(IntegrationValidators.validateExportRfc3339Optional(
        startTime, 'start_time'));
    _throwIfInvalid(IntegrationValidators.validateExportRfc3339Optional(
        endTime, 'end_time'));

    final query = <String, dynamic>{'format': format.trim().toLowerCase()};
    if (startTime != null && startTime.trim().isNotEmpty) {
      query['start_time'] = startTime.trim();
    }
    if (endTime != null && endTime.trim().isNotEmpty) {
      query['end_time'] = endTime.trim();
    }

    return _api.get<T>(
      '/integration/export',
      queryParameters: query,
      options: options,
    );
  }

  /// GET /integration/google/auth
  Future<Response<T>> getGoogleAuth<T>() =>
      _api.get<T>('/integration/google/auth');

  /// GET /integration/google/callback?code=&state=
  Future<Response<T>> getGoogleCallback<T>({
    required String code,
    required String state,
  }) async {
    _throwIfInvalid(IntegrationValidators.validateGoogleOAuthCallback(
      code: code,
      state: state,
    ));
    return _api.get<T>(
      '/integration/google/callback',
      queryParameters: {'code': code, 'state': state},
    );
  }

  /// POST /integration/google/disconnect
  Future<Response<T>> postGoogleDisconnect<T>() =>
      _api.post<T>('/integration/google/disconnect');

  /// GET /integration/google/status
  Future<Response<T>> getGoogleStatus<T>() =>
      _api.get<T>('/integration/google/status');

  /// POST /integration/google/sync
  Future<Response<T>> postGoogleSync<T>(Map<String, dynamic> body) async {
    final direction = body['direction']?.toString() ?? '';
    _throwIfInvalid(
        IntegrationValidators.validateGoogleSyncDirection(direction));
    return _api.post<T>('/integration/google/sync', data: body);
  }

  /// POST /integration/google/watch
  Future<Response<T>> postGoogleWatch<T>(Map<String, dynamic> body) async {
    _throwIfInvalid(IntegrationValidators.validateGoogleWatchBody(body));
    return _api.post<T>('/integration/google/watch', data: body);
  }

  /// POST /integration/google/webhook (server-facing; included for parity)
  Future<Response<T>> postGoogleWebhook<T>(Map<String, dynamic> body) =>
      _api.post<T>('/integration/google/webhook', data: body);
}
