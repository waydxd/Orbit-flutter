// Custom exceptions for chat API error handling
//
// These exceptions are used throughout the chat module to provide
// meaningful error information based on the Orbit-core API responses.

/// Base exception class for all chat/API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Exception for authentication-related errors (401, 403)
/// Indicates that the user needs to re-authenticate
class AuthException extends ApiException {
  AuthException(super.message, {super.statusCode});
}

/// Exception for network connectivity issues
/// Indicates connection timeout, no internet, or unreachable server
class NetworkException extends ApiException {
  final bool isRetryable;

  NetworkException(super.message, {super.statusCode, this.isRetryable = true});
}

/// Exception for validation errors (400)
/// Indicates invalid request data was sent
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException(super.message, {super.statusCode, this.errors});
}

/// Exception for server-side errors (5xx)
/// Indicates the server encountered an error processing the request
class ServerException extends ApiException {
  final bool isRetryable;

  ServerException(super.message, {super.statusCode, this.isRetryable = true});
}

/// Exception for resource not found errors (404)
/// Indicates the requested resource (conversation, message) was not found
class NotFoundException extends ApiException {
  NotFoundException(super.message, {super.statusCode});
}

/// Exception for rate limiting (429)
/// Indicates too many requests were sent
class RateLimitException extends ApiException {
  final Duration? retryAfter;

  RateLimitException(super.message, {super.statusCode, this.retryAfter});
}

/// Exception for resource conflicts (409)
/// Indicates a conflict occurred (e.g., duplicate action, version mismatch)
class ConflictException extends ApiException {
  ConflictException(super.message, {super.statusCode});
}

/// Exception for expired actions (410)
/// Indicates the action has expired and can no longer be confirmed/cancelled
class ActionExpiredException extends ApiException {
  ActionExpiredException(super.message, {super.statusCode});
}
