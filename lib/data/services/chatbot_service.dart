import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/environment.dart';
import '../models/chat_action.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/chat_context.dart';

/// Service for handling chatbot communication with the backend
class ChatbotService {
  final Dio _dio;
  final String _wsBaseUrl;
  WebSocketChannel? _wsChannel;
  StreamController<String>? _streamController;

  ChatbotService({Dio? dio, String? wsBaseUrl})
      : _dio = dio ?? Dio(),
        _wsBaseUrl = wsBaseUrl ?? _getDefaultWsUrl() {
    _dio.options.baseUrl = EnvironmentConfig.baseUrl;
    _dio.options.headers = {'Content-Type': 'application/json'};
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  static String _getDefaultWsUrl() {
    return EnvironmentConfig.wsUrl;
  }

  /// Send a message and get a response
  /// Backend endpoint: POST /api/v1/chat/messages
  Future<ChatMessage> sendMessage({
    required String userId,
    required String sessionId,
    required String message,
    ChatContext? context,
  }) async {
    try {
      // Build request data - using 'message' to match backend PostMessageRequest schema
      final Map<String, dynamic> requestData = {
        'message': message,
      };

      // Only include conversation_id if it's not a temp session
      // Backend validates it as UUID, so temp sessions should not send it
      if (!sessionId.startsWith('temp-')) {
        requestData['conversation_id'] = sessionId;
      }

      // Include context if provided
      if (context != null) {
        requestData['context'] = context.toJson();
      }

      final response = await _dio.post(
        '/api/v1/chat/messages',
        data: requestData,
      );

      if (response.statusCode == 200) {
        // Map backend response to ChatMessage
        final data = response.data;
        return ChatMessage(
          messageId: data['correlation_id'] ?? '',
          sessionId: data['conversation_id'] ?? sessionId,
          role: MessageRole.assistant,
          content: data['reply'] ?? '',
          timestamp: DateTime.now(),
          actions: _parseActions(data),
        );
      }
      throw ChatbotException(
          'Failed to send message: ${response.statusMessage}');
    } on DioException catch (e) {
      throw ChatbotException(_handleDioError(e));
    }
  }

  /// Parse proposed actions from backend response
  List<ChatAction>? _parseActions(Map<String, dynamic> data) {
    final actionId = data['action_id'];
    final actionSummary = data['proposed_action_summary'];

    if (actionId != null && actionSummary != null && actionSummary.isNotEmpty) {
      return [
        ChatAction(
          label: actionSummary,
          actionType: ActionType.createEvent,
          payload: {'action_id': actionId},
        ),
      ];
    }
    return null;
  }

  /// Stream a response using WebSocket
  Stream<String> streamMessage({
    required String userId,
    required String sessionId,
    required String message,
    ChatContext? context,
  }) {
    _streamController?.close();
    _streamController = StreamController<String>();

    try {
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('$_wsBaseUrl/api/v1/chat/stream'),
      );

      _wsChannel!.sink.add(jsonEncode({
        'conversation_id': sessionId,
        'message': message,
        'context': context?.toJson(),
      }));

      _wsChannel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            if (decoded['type'] == 'chunk') {
              _streamController!.add(decoded['content'] ?? '');
            } else if (decoded['type'] == 'done') {
              _streamController!.close();
            } else if (decoded['type'] == 'error') {
              _streamController!.addError(
                ChatbotException(decoded['message'] ?? 'Stream error'),
              );
            }
          } catch (e) {
            _streamController!
                .addError(ChatbotException('Failed to parse stream data'));
          }
        },
        onError: (error) {
          _streamController!
              .addError(ChatbotException('WebSocket error: $error'));
        },
        onDone: () {
          if (!_streamController!.isClosed) {
            _streamController!.close();
          }
        },
      );
    } catch (e) {
      _streamController!
          .addError(ChatbotException('Failed to connect to stream: $e'));
    }

    return _streamController!.stream;
  }

  /// Close streaming connection
  void closeStream() {
    _wsChannel?.sink.close();
    _streamController?.close();
  }

  /// Get chat history for a conversation
  /// Backend endpoint: GET /api/v1/chat/conversations/{conversation_id}
  Future<List<ChatMessage>> getChatHistory(String sessionId) async {
    try {
      final response = await _dio.get('/api/v1/chat/conversations/$sessionId');

      if (response.statusCode == 200) {
        final data = response.data;
        final messages = data['messages'] as List? ?? [];
        return messages
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      throw ChatbotException('Failed to get chat history');
    } on DioException catch (e) {
      throw ChatbotException(_handleDioError(e));
    }
  }

  /// Create a new chat session
  /// The backend creates sessions automatically on first message,
  /// so we simulate session creation client-side
  Future<ChatSession> createSession(String userId) async {
    // Backend doesn't have explicit session creation -
    // conversations are created on first message
    // Return a temporary session that will be updated after first message
    final sessionId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    return ChatSession(
      sessionId: sessionId,
      userId: userId,
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: 0,
    );
  }

  /// Get all sessions for a user
  /// Note: Backend may not have this endpoint - using local storage fallback
  Future<List<ChatSession>> getSessions(String userId) async {
    try {
      // Try to get sessions from backend if endpoint exists
      final response = await _dio.get('/api/v1/chat/sessions/$userId');

      if (response.statusCode == 200) {
        final sessions = response.data['sessions'] as List? ?? [];
        return sessions
            .map((s) => ChatSession.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // If endpoint doesn't exist (404), return empty list
      // Sessions will be managed locally
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw ChatbotException(_handleDioError(e));
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      final response =
          await _dio.delete('/api/v1/chat/conversations/$sessionId');

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw ChatbotException('Failed to delete session');
      }
    } on DioException catch (e) {
      // Ignore 404 errors - session might not exist on backend
      if (e.response?.statusCode != 404) {
        throw ChatbotException(_handleDioError(e));
      }
    }
  }

  /// Confirm a proposed action
  /// Backend endpoint: POST /api/v1/chat/actions/{action_id}/confirm
  Future<void> confirmAction({
    required String actionId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/chat/actions/$actionId/confirm',
        data: {'idempotency_key': idempotencyKey},
      );

      if (response.statusCode != 200) {
        throw ChatbotException('Failed to confirm action');
      }
    } on DioException catch (e) {
      throw ChatbotException(_handleDioError(e));
    }
  }

  /// Cancel a proposed action
  /// Backend endpoint: POST /api/v1/chat/actions/{action_id}/cancel
  Future<void> cancelAction(String actionId) async {
    try {
      final response = await _dio.post('/api/v1/chat/actions/$actionId/cancel');

      if (response.statusCode != 200) {
        throw ChatbotException('Failed to cancel action');
      }
    } on DioException catch (e) {
      throw ChatbotException(_handleDioError(e));
    }
  }

  /// Get action details
  /// Backend endpoint: GET /api/v1/chat/actions/{action_id}
  Future<Map<String, dynamic>> getActionDetails(String actionId) async {
    try {
      final response = await _dio.get('/api/v1/chat/actions/$actionId');

      if (response.statusCode == 200) {
        return response.data;
      }
      throw ChatbotException('Failed to get action details');
    } on DioException catch (e) {
      throw ChatbotException(_handleDioError(e));
    }
  }

  /// Send context update for better responses
  Future<void> updateContext({
    required String sessionId,
    required ChatContext context,
  }) async {
    // Context is sent with each message, no separate endpoint needed
    // This is kept for API compatibility
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Connection error. Service may be unavailable.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 503) {
          return 'Service temporarily unavailable. Please try again later.';
        } else if (statusCode == 501) {
          return 'Feature not implemented yet.';
        } else if (statusCode == 401) {
          return 'Authentication required. Please log in again.';
        }
        return 'Server error: ${error.response?.statusMessage ?? 'Unknown error'}';
      default:
        return 'Network error: ${error.message ?? 'Unknown error'}';
    }
  }

  void dispose() {
    closeStream();
  }
}

/// Custom exception for chatbot errors
class ChatbotException implements Exception {
  final String message;
  final bool isRetryable;

  ChatbotException(this.message, {this.isRetryable = true});

  @override
  String toString() => message;
}
