import 'package:flutter/material.dart';

/// Data model for a card in the card stack carousel.
class CardStackItem {
  final String id;
  final String title;
  final String? description;
  final String? imageSrc;
  final String? href;
  final String? ctaLabel;
  final String? tag;
  final Color? tagColor;
  final DateTime? dateTime;
  final bool isTask;

  const CardStackItem({
    required this.id,
    required this.title,
    this.description,
    this.imageSrc,
    this.href,
    this.ctaLabel,
    this.tag,
    this.tagColor,
    this.dateTime,
    this.isTask = false,
  });

  /// Creates a CardStackItem from a TaskModel or EventModel.
  factory CardStackItem.fromTask({
    required String id,
    required String title,
    String? description,
    DateTime? dueDate,
  }) {
    return CardStackItem(
      id: id,
      title: title,
      description: description,
      dateTime: dueDate,
      isTask: true,
      tag: 'Task',
      tagColor: const Color(0xFF6366F1),
    );
  }

  factory CardStackItem.fromEvent({
    required String id,
    required String title,
    String? description,
    DateTime? startTime,
  }) {
    return CardStackItem(
      id: id,
      title: title,
      description: description,
      dateTime: startTime,
      isTask: false,
      tag: 'Event',
      tagColor: const Color(0xFF8B80F0),
    );
  }
}
