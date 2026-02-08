import 'package:equatable/equatable.dart';

/// Status of a pending action
enum ActionStatus {
  pending,
  confirmed,
  cancelled,
  expired,
  failed,
}

extension ActionStatusExtension on ActionStatus {
  String get value {
    switch (this) {
      case ActionStatus.pending:
        return 'pending';
      case ActionStatus.confirmed:
        return 'confirmed';
      case ActionStatus.cancelled:
        return 'cancelled';
      case ActionStatus.expired:
        return 'expired';
      case ActionStatus.failed:
        return 'failed';
    }
  }

  static ActionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ActionStatus.pending;
      case 'confirmed':
        return ActionStatus.confirmed;
      case 'cancelled':
        return ActionStatus.cancelled;
      case 'expired':
        return ActionStatus.expired;
      case 'failed':
        return ActionStatus.failed;
      default:
        return ActionStatus.pending;
    }
  }
}

/// Type of action that can be performed
enum ActionType {
  createEvent,
  updateEvent,
  deleteEvent,
  createTask,
  updateTask,
  deleteTask,
}

extension ActionTypeExtension on ActionType {
  String get value {
    switch (this) {
      case ActionType.createEvent:
        return 'create_event';
      case ActionType.updateEvent:
        return 'update_event';
      case ActionType.deleteEvent:
        return 'delete_event';
      case ActionType.createTask:
        return 'create_task';
      case ActionType.updateTask:
        return 'update_task';
      case ActionType.deleteTask:
        return 'delete_task';
    }
  }

  String get displayName {
    switch (this) {
      case ActionType.createEvent:
        return 'Create Event';
      case ActionType.updateEvent:
        return 'Update Event';
      case ActionType.deleteEvent:
        return 'Delete Event';
      case ActionType.createTask:
        return 'Create Task';
      case ActionType.updateTask:
        return 'Update Task';
      case ActionType.deleteTask:
        return 'Delete Task';
    }
  }

  static ActionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'create_event':
        return ActionType.createEvent;
      case 'update_event':
        return ActionType.updateEvent;
      case 'delete_event':
        return ActionType.deleteEvent;
      case 'create_task':
        return ActionType.createTask;
      case 'update_task':
        return ActionType.updateTask;
      case 'delete_task':
        return ActionType.deleteTask;
      default:
        return ActionType.createEvent;
    }
  }
}

/// Proposed action data for calendar events
class ProposedEventAction extends Equatable {
  final String title;
  final int startTime;
  final int endTime;
  final String? description;
  final String? location;

  const ProposedEventAction({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
  });

  factory ProposedEventAction.fromJson(Map<String, dynamic> json) {
    return ProposedEventAction(
      title: json['title'] ?? '',
      startTime: json['start_time'] ?? 0,
      endTime: json['end_time'] ?? 0,
      description: json['description'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'start_time': startTime,
        'end_time': endTime,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      };

  DateTime get startDateTime =>
      DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
  DateTime get endDateTime =>
      DateTime.fromMillisecondsSinceEpoch(endTime * 1000);

  @override
  List<Object?> get props => [title, startTime, endTime, description, location];
}

/// Represents a pending action from the AI agent
class PendingAction extends Equatable {
  final String id;
  final String actionId;
  final String userId;
  final String conversationId;
  final Map<String, dynamic> proposedAction;
  final ActionType actionType;
  final String idempotencyKey;
  final ActionStatus status;
  final int version;
  final String correlationId;
  final Map<String, dynamic> agentMetadata;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  const PendingAction({
    required this.id,
    required this.actionId,
    required this.userId,
    required this.conversationId,
    required this.proposedAction,
    required this.actionType,
    required this.idempotencyKey,
    required this.status,
    required this.version,
    required this.correlationId,
    this.agentMetadata = const {},
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'] ?? '',
      actionId: json['action_id'] ?? '',
      userId: json['user_id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      proposedAction: json['proposed_action'] as Map<String, dynamic>? ?? {},
      actionType: ActionTypeExtension.fromString(json['action_type'] ?? ''),
      idempotencyKey: json['idempotency_key'] ?? '',
      status: ActionStatusExtension.fromString(json['status'] ?? 'pending'),
      version: json['version'] ?? 1,
      correlationId: json['correlation_id'] ?? '',
      agentMetadata: json['agent_metadata'] as Map<String, dynamic>? ?? {},
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action_id': actionId,
        'user_id': userId,
        'conversation_id': conversationId,
        'proposed_action': proposedAction,
        'action_type': actionType.value,
        'idempotency_key': idempotencyKey,
        'status': status.value,
        'version': version,
        'correlation_id': correlationId,
        'agent_metadata': agentMetadata,
        if (errorMessage != null) 'error_message': errorMessage,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };

  /// Get the proposed action as an event action if applicable
  ProposedEventAction? get proposedEventAction {
    if (actionType == ActionType.createEvent ||
        actionType == ActionType.updateEvent) {
      return ProposedEventAction.fromJson(proposedAction);
    }
    return null;
  }

  /// Check if the action is still valid (not expired)
  bool get isValid {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Check if the action is pending
  bool get isPending => status == ActionStatus.pending;

  PendingAction copyWith({
    String? id,
    String? actionId,
    String? userId,
    String? conversationId,
    Map<String, dynamic>? proposedAction,
    ActionType? actionType,
    String? idempotencyKey,
    ActionStatus? status,
    int? version,
    String? correlationId,
    Map<String, dynamic>? agentMetadata,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return PendingAction(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      proposedAction: proposedAction ?? this.proposedAction,
      actionType: actionType ?? this.actionType,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      version: version ?? this.version,
      correlationId: correlationId ?? this.correlationId,
      agentMetadata: agentMetadata ?? this.agentMetadata,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        actionId,
        userId,
        conversationId,
        proposedAction,
        actionType,
        idempotencyKey,
        status,
        version,
        correlationId,
        agentMetadata,
        errorMessage,
        createdAt,
        updatedAt,
        expiresAt,
      ];
}

/// Response from confirming an action
class ActionConfirmResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? result;
  final String? operationId;

  ActionConfirmResponse({
    required this.success,
    required this.message,
    this.result,
    this.operationId,
  });

  factory ActionConfirmResponse.fromJson(Map<String, dynamic> json) {
    return ActionConfirmResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      result: json['result'] as Map<String, dynamic>?,
      operationId: json['operation_id'],
    );
  }

  /// Get the event ID if the action created an event
  String? get eventId => result?['event_id'];
}

/// Response from cancelling an action
class ActionCancelResponse {
  final bool success;
  final String message;

  ActionCancelResponse({
    required this.success,
    required this.message,
  });

  factory ActionCancelResponse.fromJson(Map<String, dynamic> json) {
    return ActionCancelResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Chat metrics response
class ChatMetrics {
  final int totalMessages;
  final int totalConversations;
  final int totalPendingActions;
  final int totalConfirmedActions;
  final int totalCancelledActions;
  final int totalExpiredActions;
  final int totalFailedActions;
  final double avgMessageLatencyMs;
  final double avgActionLatencyMs;
  final double confirmationRatePct;
  final double successRatePct;
  final int totalErrors;
  final int validationErrors;
  final int policyViolations;
  final int conflictErrors;
  final double messagesPerMinute;
  final double actionsPerMinute;

  ChatMetrics({
    required this.totalMessages,
    required this.totalConversations,
    required this.totalPendingActions,
    required this.totalConfirmedActions,
    required this.totalCancelledActions,
    required this.totalExpiredActions,
    required this.totalFailedActions,
    required this.avgMessageLatencyMs,
    required this.avgActionLatencyMs,
    required this.confirmationRatePct,
    required this.successRatePct,
    required this.totalErrors,
    required this.validationErrors,
    required this.policyViolations,
    required this.conflictErrors,
    required this.messagesPerMinute,
    required this.actionsPerMinute,
  });

  factory ChatMetrics.fromJson(Map<String, dynamic> json) {
    return ChatMetrics(
      totalMessages: json['total_messages'] ?? 0,
      totalConversations: json['total_conversations'] ?? 0,
      totalPendingActions: json['total_pending_actions'] ?? 0,
      totalConfirmedActions: json['total_confirmed_actions'] ?? 0,
      totalCancelledActions: json['total_cancelled_actions'] ?? 0,
      totalExpiredActions: json['total_expired_actions'] ?? 0,
      totalFailedActions: json['total_failed_actions'] ?? 0,
      avgMessageLatencyMs: (json['avg_message_latency_ms'] ?? 0).toDouble(),
      avgActionLatencyMs: (json['avg_action_latency_ms'] ?? 0).toDouble(),
      confirmationRatePct: (json['confirmation_rate_pct'] ?? 0).toDouble(),
      successRatePct: (json['success_rate_pct'] ?? 0).toDouble(),
      totalErrors: json['total_errors'] ?? 0,
      validationErrors: json['validation_errors'] ?? 0,
      policyViolations: json['policy_violations'] ?? 0,
      conflictErrors: json['conflict_errors'] ?? 0,
      messagesPerMinute: (json['messages_per_minute'] ?? 0).toDouble(),
      actionsPerMinute: (json['actions_per_minute'] ?? 0).toDouble(),
    );
  }
}

