import '../models/event_model.dart';

/// The calendar event that ends last among those with `endTime <= proposedStart`
/// (immediate predecessor on the timeline for travel buffer checks).
EventModel? findPriorConsecutiveEvent({
  required List<EventModel> events,
  required String currentUserId,
  required DateTime proposedStart,
  String? excludeEventId,
}) {
  EventModel? best;
  for (final e in events) {
    if (e.userId != currentUserId) continue;
    if (excludeEventId != null && e.id == excludeEventId) continue;
    if (e.endTime.isAfter(proposedStart)) continue;
    if (best == null || e.endTime.isAfter(best.endTime)) {
      best = e;
    }
  }
  return best;
}
