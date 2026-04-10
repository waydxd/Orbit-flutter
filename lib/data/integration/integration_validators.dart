/// Client-side validation aligned with Orbit integration OpenAPI.
library;

/// Thrown when a request fails validation before it is sent.
class IntegrationValidationException implements Exception {
  IntegrationValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class IntegrationValidators {
  IntegrationValidators._();

  static const exportFormats = {'ics', 'csv'};

  static const googleSyncDirections = {
    'from_google',
    'to_google',
    'bidirectional',
  };

  /// Normalized lower-case extension including dot, e.g. `.ics`, or `` if none.
  static String normalizedExtension(String fileName) {
    final trimmed = fileName.trim();
    final dot = trimmed.lastIndexOf('.');
    if (dot < 0 || dot == trimmed.length - 1) return '';
    return trimmed.substring(dot).toLowerCase();
  }

  /// Import accepts `.ics` or `.csv` on the server; calendar MIME aliases are normalized to `.ics`.
  static const _importCalendarAliases = {'.ical', '.ifb', '.icalendar'};

  /// Returns `null` if [fileName] can be sent (possibly after normalization), or an error message.
  static String? validateImportFileName(String fileName) {
    final ext = normalizedExtension(fileName);
    if (ext == '.ics' || ext == '.csv') return null;
    if (_importCalendarAliases.contains(ext)) return null;
    if (ext.isEmpty) {
      return 'Choose a file with a .ics or .csv extension.';
    }
    return 'Unsupported file type ($ext). Use .ics or .csv.';
  }

  /// True if this file should be uploaded using a `.ics` filename for the backend router.
  static bool importShouldUseIcsFileName(String fileName) {
    final ext = normalizedExtension(fileName);
    return ext == '.ics' || _importCalendarAliases.contains(ext);
  }

  /// Export query param `format`: enum ics | csv.
  static String? validateExportFormat(String format) {
    final f = format.trim().toLowerCase();
    if (exportFormats.contains(f)) return null;
    return 'Export format must be "ics" or "csv".';
  }

  /// Optional `start_time` / `end_time` for GET export (RFC3339).
  static String? validateExportRfc3339Optional(
      String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    if (DateTime.tryParse(value.trim()) == null) {
      return '$fieldName must be a valid ISO-8601 / RFC3339 date-time.';
    }
    return null;
  }

  /// POST /integration/sync
  static String? validateSyncRequest({
    required String source,
    required String target,
  }) {
    if (source.trim().isEmpty) return 'source is required.';
    if (target.trim().isEmpty) return 'target is required.';
    return null;
  }

  /// POST /integration/webhooks — body is arbitrary JSON object (may be empty).
  static String? validateWebhookPayload(Map<String, dynamic>? body) {
    if (body == null)
      return 'Webhook body is required (use an empty object {}).';
    return null;
  }

  /// POST /integration/external/connect
  static String? validateExternalConnect({
    required String service,
    required String apiKey,
  }) {
    if (service.trim().isEmpty) return 'service is required.';
    if (apiKey.trim().isEmpty) return 'api_key is required.';
    return null;
  }

  /// POST /integration/external/disconnect
  static String? validateExternalDisconnect({required String service}) {
    if (service.trim().isEmpty) return 'service is required.';
    return null;
  }

  /// POST /integration/google/sync
  static String? validateGoogleSyncDirection(String direction) {
    final d = direction.trim().toLowerCase();
    if (!googleSyncDirections.contains(d)) {
      return 'direction must be one of: from_google, to_google, bidirectional.';
    }
    return null;
  }

  /// POST /integration/google/watch — non-null JSON object.
  static String? validateGoogleWatchBody(Map<String, dynamic>? body) {
    if (body == null) return 'Watch request body is required.';
    return null;
  }

  /// Google OAuth callback query params.
  static String? validateGoogleOAuthCallback({
    required String? code,
    required String? state,
  }) {
    if (code == null || code.trim().isEmpty) return 'code is required.';
    if (state == null || state.trim().isEmpty) return 'state is required.';
    return null;
  }
}
