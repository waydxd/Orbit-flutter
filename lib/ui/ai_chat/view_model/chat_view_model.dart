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

  ChatViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository(ApiClient()) {
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

    final userId = LocalStorageService.getPreference<String>('user_id');
    if (userId == null) {
      setError('User not found. Please login again.');
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

        // Update conversation ID if it's new
        if (response.containsKey('conversation_id')) {
          _conversationId = response['conversation_id'];
        }

        // Add assistant reply
        final reply = response['reply'] as String;
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
        // Remove user message if failed? Or show error state?
        // For now, just show error toast via BaseViewModel
        rethrow;
      }
    }, showLoading: true); // Show loading indicator (e.g. typing animation)
  }
}
