import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../../utils/logger.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

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

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String userId,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/messages',
        data: {
          'message': message,
          'user_id': userId,
          if (conversationId != null) 'conversation_id': conversationId,
          if (context != null) 'context': context,
        },
      );
      return response.data;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.error('Failed to send message: $errorMessage', e);
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId',
      );
      return response.data;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      Logger.error('Failed to get conversation: $errorMessage', e);
      throw Exception(errorMessage);
    }
  }
}
