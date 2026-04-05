import 'package:equatable/equatable.dart';

/// Context data sent with chat messages for better AI responses
class ChatContext extends Equatable {
  final DateTime currentDate;
  final List<Map<String, dynamic>> upcomingEvents;
  final Map<String, dynamic> userPreferences;

  const ChatContext({
    required this.currentDate,
    this.upcomingEvents = const [],
    this.userPreferences = const {},
  });

  Map<String, dynamic> toJson() => {
        'current_date': currentDate.toIso8601String().split('T')[0],
        'upcoming_events': upcomingEvents,
        'user_preferences': userPreferences,
      };

  factory ChatContext.fromJson(Map<String, dynamic> json) {
    return ChatContext(
      currentDate: json['current_date'] != null
          ? DateTime.parse(json['current_date'])
          : DateTime.now(),
      upcomingEvents: json['upcoming_events'] != null
          ? List<Map<String, dynamic>>.from(
              (json['upcoming_events'] as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : [],
      userPreferences: json['user_preferences'] != null
          ? Map<String, dynamic>.from(json['user_preferences'])
          : {},
    );
  }

  ChatContext copyWith({
    DateTime? currentDate,
    List<Map<String, dynamic>>? upcomingEvents,
    Map<String, dynamic>? userPreferences,
  }) {
    return ChatContext(
      currentDate: currentDate ?? this.currentDate,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }

  @override
  List<Object?> get props => [currentDate, upcomingEvents, userPreferences];
}
