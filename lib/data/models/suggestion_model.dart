import 'base_model.dart';

/// Represents an AI-generated suggestion for an event
class SuggestionModel extends BaseModel {
  final String id;
  final String eventId;
  final String type; // weather, transport, dress_code, nearby_places, etc.
  final String title;
  final String content;
  final String? icon;
  final Map<String, dynamic>? metadata;
  final DateTime generatedAt;

  const SuggestionModel({
    required this.id,
    required this.eventId,
    required this.type,
    required this.title,
    required this.content,
    this.icon,
    this.metadata,
    required this.generatedAt,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      icon: json['icon'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'type': type,
      'title': title,
      'content': content,
      'icon': icon,
      'metadata': metadata,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        type,
        title,
        content,
        icon,
        metadata,
        generatedAt,
      ];

  SuggestionModel copyWith({
    String? id,
    String? eventId,
    String? type,
    String? title,
    String? content,
    String? icon,
    Map<String, dynamic>? metadata,
    DateTime? generatedAt,
  }) {
    return SuggestionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Response model for AI suggestions from backend
class SuggestionResponse extends BaseModel {
  final List<SuggestionModel> suggestions;
  final String? summary;
  final Map<String, dynamic>? toolResults;
  final bool isLoading;
  final String? error;

  const SuggestionResponse({
    required this.suggestions,
    this.summary,
    this.toolResults,
    this.isLoading = false,
    this.error,
  });

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['suggestions'] as List<dynamic>? ?? [];
    return SuggestionResponse(
      suggestions: suggestionsJson
          .map((s) => SuggestionModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
      toolResults: json['tool_results'] as Map<String, dynamic>?,
    );
  }

  factory SuggestionResponse.empty() {
    return const SuggestionResponse(suggestions: []);
  }

  factory SuggestionResponse.loading() {
    return const SuggestionResponse(suggestions: [], isLoading: true);
  }

  factory SuggestionResponse.error(String message) {
    return SuggestionResponse(suggestions: [], error: message);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'summary': summary,
      'tool_results': toolResults,
    };
  }

  @override
  List<Object?> get props => [
        suggestions,
        summary,
        toolResults,
        isLoading,
        error,
      ];

  SuggestionResponse copyWith({
    List<SuggestionModel>? suggestions,
    String? summary,
    Map<String, dynamic>? toolResults,
    bool? isLoading,
    String? error,
  }) {
    return SuggestionResponse(
      suggestions: suggestions ?? this.suggestions,
      summary: summary ?? this.summary,
      toolResults: toolResults ?? this.toolResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Enum for suggestion types
enum SuggestionType {
  weather,
  transport,
  dressCode,
  nearbyPlaces,
  nearbyRestaurants,
  schedule,
  general;

  String get displayName {
    switch (this) {
      case SuggestionType.weather:
        return 'Weather';
      case SuggestionType.transport:
        return 'Transportation';
      case SuggestionType.dressCode:
        return 'What to Wear';
      case SuggestionType.nearbyPlaces:
        return 'Nearby Attractions';
      case SuggestionType.nearbyRestaurants:
        return 'Nearby Restaurants';
      case SuggestionType.schedule:
        return 'Schedule Tips';
      case SuggestionType.general:
        return 'Suggestions';
    }
  }

  String get iconName {
    switch (this) {
      case SuggestionType.weather:
        return 'cloud';
      case SuggestionType.transport:
        return 'directions_car';
      case SuggestionType.dressCode:
        return 'checkroom';
      case SuggestionType.nearbyPlaces:
        return 'place';
      case SuggestionType.nearbyRestaurants:
        return 'restaurant';
      case SuggestionType.schedule:
        return 'schedule';
      case SuggestionType.general:
        return 'lightbulb';
    }
  }

  static SuggestionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'weather':
        return SuggestionType.weather;
      case 'transport':
      case 'transportation':
        return SuggestionType.transport;
      case 'dress_code':
      case 'dresscode':
        return SuggestionType.dressCode;
      case 'nearby_places':
      case 'nearbyplaces':
        return SuggestionType.nearbyPlaces;
      case 'nearby_restaurants':
      case 'nearbyrestaurants':
        return SuggestionType.nearbyRestaurants;
      case 'schedule':
        return SuggestionType.schedule;
      default:
        return SuggestionType.general;
    }
  }
}

