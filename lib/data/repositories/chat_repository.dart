import '../services/api_client.dart';
import '../../utils/logger.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

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
      Logger.error('Failed to send message', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId',
      );
      return response.data;
    } catch (e) {
      Logger.error('Failed to get conversation', e);
      rethrow;
    }
  }
}

