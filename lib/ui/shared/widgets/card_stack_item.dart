import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/hashtag_palette.dart';

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
      tagColor: AppColors.secondary,
    );
  }

  factory CardStackItem.fromEvent({
    required String id,
    required String title,
    String? description,
    DateTime? startTime,
    List<String> hashtags = const [],
  }) {
    final accent = accentForEventDisplay(title: title, hashtags: hashtags);
    final tagLabel = hashtags.isNotEmpty
        ? '#${stripLeadingHashtagForDisplay(hashtags.first)}'
        : 'Event';

    return CardStackItem(
      id: id,
      title: title,
      description: description,
      dateTime: startTime,
      isTask: false,
      tag: tagLabel,
      tagColor: accent,
    );
  }
}
