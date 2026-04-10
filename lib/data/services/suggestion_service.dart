import 'package:grpc/grpc.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../../generated/protos/suggestion.pbgrpc.dart';
import '../../config/app_config.dart';
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

  OrbitSuggestionService._internal() {
    _channel = ClientChannel(
      'wayd.zapto.org',
      port: 443,
      options: const ChannelOptions(credentials: ChannelCredentials.secure()),
    );
    _stub = SuggestionServiceClient(_channel);
  }

  Future<CallOptions> _getCallOptions() async {
    final token = await LocalStorageService.getSecure(AppConfig.accessTokenKey);
    return CallOptions(
      timeout: const Duration(seconds: 60),
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

  Future<List<Suggestion>> getSuggestionsForEvent(EventModel event,
      {String userId = '', bool forceRegenerate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'sug_data_${event.id}';
    final dateKey = 'sug_date_${event.id}';

    // Check cache: Event didn't update since last fetch.
    if (!forceRegenerate) {
      final cachedDateStr = prefs.getString(dateKey);
      if (cachedDateStr != null) {
        bool isSameTime = false;
        try {
          isSameTime =
              DateTime.parse(cachedDateStr).isAtSameMomentAs(event.updatedAt);
        } catch (_) {}

        if (isSameTime ||
            cachedDateStr == event.updatedAt.toUtc().toIso8601String() ||
            cachedDateStr == event.updatedAt.toIso8601String()) {
          final cachedData = prefs.getString(cacheKey);
          if (cachedData != null) {
            final List<dynamic> strList = jsonDecode(cachedData);
            return strList
                .map((e) => Suggestion.fromJson(e as String))
                .toList();
          }
        }
      }
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
      return [];
    }
  }

  Future<List<Suggestion>> getDailySuggestions(
      String date, UserModel? user, List<EventModel> recentEvents,
      {bool forceRegenerate = false}) async {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } on FormatException {
      Logger.errorWithTag(
          'OrbitSuggestionService', 'Invalid date format: $date, falling back to today');
      parsedDate = DateTime.now();
    }
    final dateStr =
        '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    final eventsHash = _computeEventsHash(recentEvents);

    final prefs = await SharedPreferences.getInstance();
    final dailyCacheKey = 'daily_sug_data_$dateStr';
    final dailyHashKey = 'daily_sug_hash_$dateStr';

    // Check daily cache: Same day and no events updated/created
    if (!forceRegenerate) {
      final savedHash = prefs.getInt(dailyHashKey);
      if (savedHash != null && savedHash == eventsHash) {
        final cachedData = prefs.getString(dailyCacheKey);
        if (cachedData != null) {
          final List<dynamic> strList = jsonDecode(cachedData);
          return strList.map((e) => Suggestion.fromJson(e as String)).toList();
        }
      }
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
      return [];
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
