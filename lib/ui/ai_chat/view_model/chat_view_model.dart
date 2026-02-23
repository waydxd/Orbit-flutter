import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/view_models/base_view_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/services/local_storage_service.dart';

class ChatViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;
  final List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _isSending = false;

  ChatViewModel({required ChatRepository chatRepository})
      : _chatRepository = chatRepository {
    // Add initial welcome message
    _messages.add(
      ChatMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: 'Hi, I am Orbi! How can I help you?',
        createdAt: DateTime.now(),
      ),
    );
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Prevent sending multiple messages simultaneously
    if (_isSending) return;

    _isSending = true;

    final userId = LocalStorageService.getPreference<String>('user_id');
    if (userId == null) {
      setError('User not found. Please login again.');
      _isSending = false;
      return;
    }

    // Add user message to UI immediately
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    await executeAsync(() async {
      try {
        final response = await _chatRepository.sendMessage(
          message: text,
          userId: userId,
          conversationId: _conversationId,
        );

        // Validate response format
        if (!response.containsKey('reply')) {
          throw Exception('Invalid response from server. Please try again.');
        }

        final reply = response['reply'] as String?;
        if (reply == null || reply.isEmpty) {
          throw Exception('Invalid response from server. Please try again.');
        }

        // Update conversation ID if it's new (only after successful response)
        if (response.containsKey('conversation_id')) {
          _conversationId = response['conversation_id'];
        }

        // Add assistant reply
        final assistantMsg = ChatMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content: reply,
          createdAt: DateTime.now(),
        );
        _messages.add(assistantMsg);

        // TODO: Handle proposed actions if any (response['proposed_action_summary'])

        notifyListeners();
      } catch (e) {
        // Remove the user message on failure
        _messages.remove(userMsg);

        // Extract error message for display
        String errorMessage =
            'Sorry, I couldn\'t send that message. Please try again.';
        if (e is Exception) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          if (msg.isNotEmpty) {
            errorMessage = msg;
          }
        }

        // Add error message in chat
        final errorMsg = ChatMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content: errorMessage,
          createdAt: DateTime.now(),
        );
        _messages.add(errorMsg);
        notifyListeners();

        // Don't rethrow - we've already handled the error in the UI
      } finally {
        _isSending = false;
      }
    }, showLoading: true); // Show loading indicator (e.g. typing animation)
  }
}
