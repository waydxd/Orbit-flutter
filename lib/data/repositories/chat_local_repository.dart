import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// Local repository for caching chat data offline
class ChatLocalRepository {
  static const String _messagesBoxName = 'chat_messages';
  static const String _sessionsBoxName = 'chat_sessions';

  Box<Map>? _messagesBox;
  Box<Map>? _sessionsBox;
  bool _isInitialized = false;

  /// Initialize Hive boxes for chat storage
  Future<void> init() async {
    if (_isInitialized) return;

    _messagesBox = await Hive.openBox<Map>(_messagesBoxName);
    _sessionsBox = await Hive.openBox<Map>(_sessionsBoxName);
    _isInitialized = true;
  }

  /// Ensure repository is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  /// Cache messages locally for a session
  Future<void> cacheMessages(String sessionId, List<ChatMessage> messages) async {
    await _ensureInitialized();
    final data = messages.map((m) => m.toJson()).toList();
    await _messagesBox!.put(sessionId, {'messages': data});
  }

  /// Get cached messages for a session
  Future<List<ChatMessage>?> getCachedMessages(String sessionId) async {
    await _ensureInitialized();
    final data = _messagesBox!.get(sessionId);
    if (data == null) return null;

    try {
      final messages = data['messages'] as List?;
      if (messages == null) return null;
      
      return messages
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Add a single message to cached messages
  Future<void> addMessageToCache(String sessionId, ChatMessage message) async {
    await _ensureInitialized();
    final existing = await getCachedMessages(sessionId) ?? [];
    existing.add(message);
    await cacheMessages(sessionId, existing);
  }

  /// Cache sessions for a user
  Future<void> cacheSessions(String userId, List<ChatSession> sessions) async {
    await _ensureInitialized();
    final data = sessions.map((s) => s.toJson()).toList();
    await _sessionsBox!.put(userId, {'sessions': data});
  }

  /// Get cached sessions for a user
  Future<List<ChatSession>?> getCachedSessions(String userId) async {
    await _ensureInitialized();
    final data = _sessionsBox!.get(userId);
    if (data == null) return null;

    try {
      final sessions = data['sessions'] as List?;
      if (sessions == null) return null;
      
      return sessions
          .map((s) => ChatSession.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Delete cached messages for a session
  Future<void> deleteCachedMessages(String sessionId) async {
    await _ensureInitialized();
    await _messagesBox!.delete(sessionId);
  }

  /// Delete cached session from user's sessions
  Future<void> removeCachedSession(String userId, String sessionId) async {
    await _ensureInitialized();
    final sessions = await getCachedSessions(userId);
    if (sessions != null) {
      sessions.removeWhere((s) => s.sessionId == sessionId);
      await cacheSessions(userId, sessions);
    }
  }

  /// Clear all cached chat data
  Future<void> clearCache() async {
    await _ensureInitialized();
    await _messagesBox!.clear();
    await _sessionsBox!.clear();
  }

  /// Close Hive boxes
  Future<void> close() async {
    await _messagesBox?.close();
    await _sessionsBox?.close();
    _isInitialized = false;
  }
}

