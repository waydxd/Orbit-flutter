import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/chat_context.dart';
import '../services/chatbot_service.dart';
import '../repositories/chat_local_repository.dart';

/// State class for chat functionality
class ChatState {
  final List<ChatMessage> messages;
  final List<ChatSession> sessions;
  final bool isLoading;
  final bool isLoadingSessions;
  final String? error;
  final String? currentSessionId;
  final bool isOfflineMode;

  const ChatState({
    this.messages = const [],
    this.sessions = const [],
    this.isLoading = false,
    this.isLoadingSessions = false,
    this.error,
    this.currentSessionId,
    this.isOfflineMode = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatSession>? sessions,
    bool? isLoading,
    bool? isLoadingSessions,
    String? error,
    String? currentSessionId,
    bool? isOfflineMode,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
      error: clearError ? null : (error ?? this.error),
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Provider for managing chat state and operations
class ChatbotProvider extends ChangeNotifier {
  final ChatbotService _service;
  final ChatLocalRepository _localRepository;
  final String userId;
  final Uuid _uuid = const Uuid();

  ChatState _state = const ChatState();
  ChatState get state => _state;

  // Convenience getters
  List<ChatMessage> get messages => _state.messages;
  List<ChatSession> get sessions => _state.sessions;
  bool get isLoading => _state.isLoading;
  bool get isLoadingSessions => _state.isLoadingSessions;
  String? get error => _state.error;
  String? get currentSessionId => _state.currentSessionId;
  bool get isOfflineMode => _state.isOfflineMode;
  bool get hasError => _state.error != null;

  ChatbotProvider({
    required this.userId,
    ChatbotService? service,
    ChatLocalRepository? localRepository,
  })  : _service = service ?? ChatbotService(),
        _localRepository = localRepository ?? ChatLocalRepository();

  void _updateState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Initialize the provider and local repository
  Future<void> initialize() async {
    await _localRepository.init();
    await loadSessions();
  }

  /// Load all chat sessions for the user
  Future<void> loadSessions() async {
    _updateState(_state.copyWith(isLoadingSessions: true, clearError: true));

    try {
      final sessions = await _service.getSessions(userId);
      await _localRepository.cacheSessions(userId, sessions);
      _updateState(_state.copyWith(
        sessions: sessions,
        isLoadingSessions: false,
        isOfflineMode: false,
      ));
    } on ChatbotException catch (e) {
      // Try loading from cache
      final cachedSessions = await _localRepository.getCachedSessions(userId);
      if (cachedSessions != null && cachedSessions.isNotEmpty) {
        _updateState(_state.copyWith(
          sessions: cachedSessions,
          isLoadingSessions: false,
          isOfflineMode: true,
          error: 'Offline mode: ${e.message}',
        ));
      } else {
        _updateState(_state.copyWith(
          isLoadingSessions: false,
          error: e.message,
        ));
      }
    }
  }

  /// Initialize or load a chat session
  Future<void> initSession({String? sessionId}) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));

    try {
      String activeSessionId;

      if (sessionId != null) {
        // Load existing session
        activeSessionId = sessionId;
        List<ChatMessage> history;

        try {
          history = await _service.getChatHistory(sessionId);
          await _localRepository.cacheMessages(sessionId, history);
        } on ChatbotException {
          // Try loading from cache
          final cachedMessages =
              await _localRepository.getCachedMessages(sessionId);
          if (cachedMessages != null) {
            history = cachedMessages;
            _updateState(_state.copyWith(isOfflineMode: true));
          } else {
            rethrow;
          }
        }

        _updateState(_state.copyWith(
          messages: history,
          currentSessionId: activeSessionId,
          isLoading: false,
        ));
      } else {
        // Create new session
        try {
          final session = await _service.createSession(userId);
          activeSessionId = session.sessionId;

          // Add to sessions list
          final updatedSessions = [session, ..._state.sessions];
          await _localRepository.cacheSessions(userId, updatedSessions);

          _updateState(_state.copyWith(
            messages: [],
            currentSessionId: activeSessionId,
            sessions: updatedSessions,
            isLoading: false,
            isOfflineMode: false,
          ));
        } on ChatbotException catch (e) {
          // Create temporary offline session
          activeSessionId = _uuid.v4();
          final offlineSession = ChatSession(
            sessionId: activeSessionId,
            userId: userId,
            title: 'New Chat (Offline)',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messageCount: 0,
          );

          final updatedSessions = [offlineSession, ..._state.sessions];

          _updateState(_state.copyWith(
            messages: [],
            currentSessionId: activeSessionId,
            sessions: updatedSessions,
            isLoading: false,
            isOfflineMode: true,
            error: 'Offline mode: ${e.message}',
          ));
        }
      }
    } on ChatbotException catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: e.message,
      ));
    }
  }

  /// Send a message and get response
  Future<void> sendMessage(String content, {ChatContext? context}) async {
    if (_state.currentSessionId == null) {
      await initSession();
    }

    if (_state.currentSessionId == null) {
      _updateState(_state.copyWith(
        error: 'Unable to create chat session',
      ));
      return;
    }

    final userMessage = ChatMessage(
      messageId: _uuid.v4(),
      sessionId: _state.currentSessionId!,
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );

    // Add user message immediately
    final updatedMessages = [..._state.messages, userMessage];
    _updateState(_state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      clearError: true,
    ));

    // Cache user message
    await _localRepository.addMessageToCache(
        _state.currentSessionId!, userMessage);

    if (_state.isOfflineMode) {
      // In offline mode, show error and keep user message
      _updateState(_state.copyWith(
        isLoading: false,
        error:
            'Cannot send messages in offline mode. Please check your connection.',
      ));
      return;
    }

    try {
      final response = await _service.sendMessage(
        userId: userId,
        sessionId: _state.currentSessionId!,
        message: content,
        context: context,
      );

      // If this was a temp session, update to the real conversation_id from backend
      String newSessionId = _state.currentSessionId!;
      if (_state.currentSessionId!.startsWith('temp-') &&
          response.sessionId.isNotEmpty) {
        newSessionId = response.sessionId;
        // Update user message with real session ID
        // final updatedUserMessage = userMessage.copyWith(sessionId: newSessionId);
        _state.messages.last.copyWith(sessionId: newSessionId);
      }

      final finalMessages = [..._state.messages, response];
      await _localRepository.cacheMessages(newSessionId, finalMessages);

      _updateState(_state.copyWith(
        messages: finalMessages,
        currentSessionId: newSessionId,
        isLoading: false,
      ));
    } on ChatbotException catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: e.message,
      ));
    }
  }

  /// Send message with streaming response
  Future<void> sendMessageStreaming(String content,
      {ChatContext? context}) async {
    if (_state.currentSessionId == null) {
      await initSession();
    }

    if (_state.currentSessionId == null) {
      _updateState(_state.copyWith(
        error: 'Unable to create chat session',
      ));
      return;
    }

    final userMessage = ChatMessage(
      messageId: _uuid.v4(),
      sessionId: _state.currentSessionId!,
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );

    final assistantMessageId = _uuid.v4();
    final assistantMessage = ChatMessage(
      messageId: assistantMessageId,
      sessionId: _state.currentSessionId!,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    // Add both messages
    final initialMessages = [..._state.messages, userMessage, assistantMessage];
    _updateState(_state.copyWith(
      messages: initialMessages,
      isLoading: true,
      clearError: true,
    ));

    // Cache user message
    await _localRepository.addMessageToCache(
        _state.currentSessionId!, userMessage);

    if (_state.isOfflineMode) {
      // Remove assistant placeholder and show error
      _updateState(_state.copyWith(
        messages: [..._state.messages]..removeLast(),
        isLoading: false,
        error:
            'Cannot send messages in offline mode. Please check your connection.',
      ));
      return;
    }

    try {
      String fullContent = '';

      await for (final chunk in _service.streamMessage(
        userId: userId,
        sessionId: _state.currentSessionId!,
        message: content,
        context: context,
      )) {
        fullContent += chunk;

        // Update the streaming message
        final updatedMessages = _state.messages.map((m) {
          if (m.messageId == assistantMessageId) {
            return m.copyWith(content: fullContent);
          }
          return m;
        }).toList();

        _updateState(_state.copyWith(messages: updatedMessages));
      }

      // Mark streaming as complete
      final finalMessages = _state.messages.map((m) {
        if (m.messageId == assistantMessageId) {
          return m.copyWith(isStreaming: false);
        }
        return m;
      }).toList();

      await _localRepository.cacheMessages(
          _state.currentSessionId!, finalMessages);

      _updateState(_state.copyWith(
        messages: finalMessages,
        isLoading: false,
      ));
    } on ChatbotException catch (e) {
      // Remove empty assistant message on error
      final messagesWithoutEmpty = _state.messages.where((m) {
        if (m.messageId == assistantMessageId && m.content.isEmpty) {
          return false;
        }
        return true;
      }).toList();

      _updateState(_state.copyWith(
        messages: messagesWithoutEmpty,
        isLoading: false,
        error: e.message,
      ));
    }
  }

  /// Clear current chat and start new
  void clearChat() {
    _updateState(_state.copyWith(
      messages: [],
      currentSessionId: null,
      clearError: true,
    ));
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      if (!_state.isOfflineMode) {
        await _service.deleteSession(sessionId);
      }

      // Remove from local cache
      await _localRepository.deleteCachedMessages(sessionId);
      await _localRepository.removeCachedSession(userId, sessionId);

      // Update state
      final updatedSessions =
          _state.sessions.where((s) => s.sessionId != sessionId).toList();

      if (_state.currentSessionId == sessionId) {
        _updateState(_state.copyWith(
          sessions: updatedSessions,
          messages: [],
          currentSessionId: null,
        ));
      } else {
        _updateState(_state.copyWith(sessions: updatedSessions));
      }
    } on ChatbotException catch (e) {
      _updateState(_state.copyWith(error: e.message));
    }
  }

  /// Clear error state
  void clearError() {
    _updateState(_state.copyWith(clearError: true));
  }

  Future<void> retryConnection() async {
    _updateState(_state.copyWith(isOfflineMode: false, clearError: true));
    await loadSessions();
  }

  @override
  void dispose() {
    _localRepository.close();
    _service.dispose();
    super.dispose();
  }
}
