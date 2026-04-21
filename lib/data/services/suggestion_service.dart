import 'package:grpc/grpc.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../../generated/protos/suggestion.pbgrpc.dart';
import '../../config/app_config.dart';
import '../../config/environment.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrbitSuggestionService {
  static final OrbitSuggestionService _instance =
      OrbitSuggestionService._internal();
  factory OrbitSuggestionService() => _instance;

  late ClientChannel _channel;
  late SuggestionServiceClient _stub;

  final Map<String, Future<List<Suggestion>>> _inFlightEventRequests = {};
  final Map<String, Future<List<Suggestion>>> _inFlightDailyRequests = {};

  OrbitSuggestionService._internal() {
    _channel = ClientChannel(
      EnvironmentConfig.grpcHost,
      port: EnvironmentConfig.grpcPort,
      options: ChannelOptions(
        credentials: EnvironmentConfig.grpcSecure
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );
    _stub = SuggestionServiceClient(_channel);
  }

  Future<CallOptions> _getCallOptions() async {
    final token = await LocalStorageService.getSecure(AppConfig.accessTokenKey);
    return CallOptions(
      timeout: const Duration(seconds: 180), // Extended from 60s to 120s
      metadata: {
        if (token != null) 'authorization': 'Bearer $token',
      },
    );
  }

  int _computeEventsHash(List<EventModel> events) {
    if (events.isEmpty) return 0;
    return events
        .map((e) => e.updatedAt.millisecondsSinceEpoch)
        .reduce((a, b) => a ^ b);
  }

  bool hasInFlightEventRequest(String eventId) =>
      _inFlightEventRequests.containsKey(eventId);

  Future<List<Suggestion>> getSuggestionsForEvent(EventModel event,
      {String userId = '', bool forceRegenerate = false}) async {
    // If a request is already in flight for this event, return that future
    // so background generation continues and UI can attach to it.
    if (_inFlightEventRequests.containsKey(event.id)) {
      return _inFlightEventRequests[event.id]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'sug_data_${event.id}';
    final dateKey = 'sug_date_${event.id}';

    // Check cache: Event didn't update since last fetch.
    if (!forceRegenerate) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> strList = jsonDecode(cachedData);
          if (strList.isNotEmpty) {
            return strList
                .map((e) => Suggestion.fromJson(e as String))
                .toList();
          }
        } catch (_) {}
      }

      // If we reach here and it's not force regenerate, do NOT automatically fetch.
      // (Returns empty list to display "No suggestions available" state and require user interaction or event update to generate)
      return [];
    }

    final request = EventRequest(
      id: event.id,
      title: event.title,
      startTime: event.startTime.toUtc().toIso8601String(),
      endTime: event.endTime.toUtc().toIso8601String(),
      location: event.location,
      description: event.description,
      userId: userId,
    );
    request.hashtags.addAll(event.hashtags);

    final future = _executeGetSuggestionsForEvent(
        event, request, prefs, cacheKey, dateKey);
    _inFlightEventRequests[event.id] = future;
    return future;
  }

  Future<List<Suggestion>> _executeGetSuggestionsForEvent(
      EventModel event,
      EventRequest request,
      SharedPreferences prefs,
      String cacheKey,
      String dateKey) async {
    try {
      final options = await _getCallOptions();
      final response = await _stub.getSuggestions(request, options: options);

      // Update cache
      final jsonList =
          response.suggestions.map((s) => s.writeToJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      await prefs.setString(dateKey, event.updatedAt.toUtc().toIso8601String());

      return response.suggestions;
    } catch (e) {
      Logger.errorWithTag(
          'OrbitSuggestionService', 'Error calling getSuggestionsForEvent: $e');

      // Fallback to cache on error (e.g. Rate Limit 429)
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> strList = jsonDecode(cachedData);
          return strList.map((e) => Suggestion.fromJson(e as String)).toList();
        } catch (_) {}
      }
      return [];
    } finally {
      _inFlightEventRequests.remove(event.id);
    }
  }

  Future<List<Suggestion>> getDailySuggestions(
      String date, UserModel? user, List<EventModel> recentEvents,
      {bool forceRegenerate = false}) async {
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('yyyy-MM-dd').parse(date);
    } on FormatException {
      Logger.errorWithTag('OrbitSuggestionService',
          'Invalid date format: $date. Expected format: yyyy-MM-dd. Falling back to today');
      parsedDate = DateTime.now();
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);
    final eventsHash = _computeEventsHash(recentEvents);

    // If a request is already in flight for this date, return that future
    if (_inFlightDailyRequests.containsKey(dateStr)) {
      return _inFlightDailyRequests[dateStr]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final dailyCacheKey = 'daily_sug_data_$dateStr';
    final dailyHashKey = 'daily_sug_hash_$dateStr';
    const dailyLastDateKey = 'daily_sug_last_date';

    // Clear previous date's cache if date changed
    final lastDate = prefs.getString(dailyLastDateKey);
    if (lastDate != null && lastDate != dateStr) {
      final oldCacheKey = 'daily_sug_data_$lastDate';
      final oldHashKey = 'daily_sug_hash_$lastDate';
      await prefs.remove(oldCacheKey);
      await prefs.remove(oldHashKey);
    }
    await prefs.setString(dailyLastDateKey, dateStr);

    // Check daily cache: Same day and no events updated/created
    if (!forceRegenerate) {
      final cachedData = prefs.getString(dailyCacheKey);
      if (cachedData != null) {
        final List<dynamic> strList = jsonDecode(cachedData);
        return strList.map((e) => Suggestion.fromJson(e as String)).toList();
      }

      // Do NOT auto-fetch daily suggestions. Require explicit user regeneration.
      return [];
    }

    final request = DailySuggestionRequest(
      date: date,
      recentEvents: recentEvents.map((evt) {
        final r = EventRequest(
          id: evt.id,
          title: evt.title,
          startTime: evt.startTime.toUtc().toIso8601String(),
          endTime: evt.endTime.toUtc().toIso8601String(),
          location: evt.location,
          description: evt.description,
        );
        r.hashtags.addAll(evt.hashtags);
        return r;
      }).toList(),
    );
    if (user != null) {
      request.user = UserRequest(
        id: user.id,
        region: user.region ?? '',
        gender: user.gender ?? '',
        birthDate: user.birthDate != null
            ? '${user.birthDate!.year}-${user.birthDate!.month.toString().padLeft(2, '0')}-${user.birthDate!.day.toString().padLeft(2, '0')}'
            : '',
      );
    }

    final future = _executeGetDailySuggestions(
        dateStr, request, eventsHash, prefs, dailyCacheKey, dailyHashKey);
    _inFlightDailyRequests[dateStr] = future;
    return future;
  }

  Future<List<Suggestion>> _executeGetDailySuggestions(
      String dateStr,
      DailySuggestionRequest request,
      int eventsHash,
      SharedPreferences prefs,
      String dailyCacheKey,
      String dailyHashKey) async {
    try {
      final response = await _stub.getDailySuggestions(request,
          options: await _getCallOptions());

      // Update daily cache
      final jsonList =
          response.suggestions.map((s) => s.writeToJson()).toList();
      await prefs.setString(dailyCacheKey, jsonEncode(jsonList));
      await prefs.setInt(dailyHashKey, eventsHash);

      return response.suggestions;
    } catch (e) {
      Logger.errorWithTag(
          'OrbitSuggestionService', 'Error calling getDailySuggestions: $e');

      // Fallback to daily cache on error
      final cachedData = prefs.getString(dailyCacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> strList = jsonDecode(cachedData);
          return strList.map((e) => Suggestion.fromJson(e as String)).toList();
        } catch (_) {}
      }
      return [];
    } finally {
      _inFlightDailyRequests.remove(dateStr);
    }
  }

  Future<void> clearDailySuggestionsCache() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    final dailyCacheKey = 'daily_sug_data_$dateStr';
    final dailyHashKey = 'daily_sug_hash_$dateStr';
    await prefs.remove(dailyCacheKey);
    await prefs.remove(dailyHashKey);
  }

  void dispose() {
    _channel.shutdown();
  }
}
