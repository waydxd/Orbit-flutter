import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/view_models/base_view_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/api_client.dart';

class ChatViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;
  final List<ChatMessage> _messages = [];
  String? _conversationId;
  final List<Completer<void>> _messageQueue = [];
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

    // Create a completer for this message to queue it
    final completer = Completer<void>();
    _messageQueue.add(completer);

    // Process the queue
    await _processMessageQueue(text, completer);
  }

  Future<void> _processMessageQueue(String text, Completer<void> completer) async {
    // Wait for previous messages to complete
    if (_isSending) {
      await completer.future;
      return;
    }

    _isSending = true;

    final userId = LocalStorageService.getPreference<String>('user_id');
    if (userId == null) {
      setError('User not found. Please login again.');
      _isSending = false;
      _messageQueue.remove(completer);
      completer.complete();
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
        final dynamic replyRaw = response['reply'];
        if (replyRaw is! String || replyRaw.isEmpty) {
          throw Exception('Invalid response from server. Please try again.');
        }

        // Update conversation ID if it's new (only after successful response)
        if (response.containsKey('conversation_id')) {
          _conversationId = response['conversation_id'];
        }

        // Add assistant reply
        final reply = replyRaw;
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
        
        // Add error message in chat
        final errorMsg = ChatMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content: 'Sorry, I couldn\'t send that message. Please try again.',
          createdAt: DateTime.now(),
        );
        _messages.add(errorMsg);
        notifyListeners();
        
        // Rethrow so BaseViewModel can handle global error UI
        rethrow;
      } finally {
        _isSending = false;
        _messageQueue.remove(completer);
        completer.complete();
        
        // Process next message in queue if any
        if (_messageQueue.isNotEmpty) {
          final nextCompleter = _messageQueue.first;
          // The next message will be processed when sendMessage is called again
        }
      }
    }, showLoading: true); // Show loading indicator (e.g. typing animation)
  }
}
