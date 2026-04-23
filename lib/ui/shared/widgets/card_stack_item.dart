import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';

/// Data model for a card in the card stack carousel.
class CardStackItem {
  final String id;
  final String title;
  final String? description;
  final List<String> hashtags;
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
    this.hashtags = const [],
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
    List<String> hashtags = const [],
  }) {
    return CardStackItem(
      id: id,
      title: title,
      description: description,
      hashtags: hashtags,
      dateTime: dueDate,
      isTask: true,
      tag: 'Task',
      tagColor: AppColors.info,
    );
  }

  factory CardStackItem.fromEvent({
    required String id,
    required String title,
    String? description,
    DateTime? startTime,
    List<String> hashtags = const [],
  }) {
    return CardStackItem(
      id: id,
      title: title,
      description: description,
      hashtags: hashtags,
      dateTime: startTime,
      isTask: false,
      tag: 'Event',
      tagColor: AppColors.primary,
    );
  }
}
