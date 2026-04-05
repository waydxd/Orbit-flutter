import 'package:equatable/equatable.dart';

/// Types of actions that can be triggered from chat responses
enum ActionType {
  createEvent,
  modifyEvent,
  deleteEvent,
  showCalendar,
  setSuggestion,
  openLink,
}

/// Represents an action that can be executed from a chat message
class ChatAction extends Equatable {
  final String label;
  final ActionType actionType;
  final Map<String, dynamic> payload;

  const ChatAction({
    required this.label,
    required this.actionType,
    required this.payload,
  });

  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      label: json['label'] ?? '',
      actionType: ActionType.values.firstWhere(
        (e) => e.name == _snakeToCamel(json['action_type'] ?? ''),
        orElse: () => ActionType.showCalendar,
      ),
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'action_type': _camelToSnake(actionType.name),
        'payload': payload,
      };

  static String _snakeToCamel(String text) {
    return text.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
  }

  static String _camelToSnake(String text) {
    return text.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
  }

  @override
  List<Object?> get props => [label, actionType, payload];
}
