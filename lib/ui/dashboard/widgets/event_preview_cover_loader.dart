import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/event_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../utils/event_image_url.dart';
import '../../core/widgets/event_cover_network_image.dart';

/// Resolves the primary cover URL like [EventDetailCoverImage]: newest-first from
/// [EventModel.imageUrls], then `GET /events/{id}/images` when the model list is empty.
class EventPreviewCoverLoader extends StatefulWidget {
  final EventModel event;
  final BoxFit fit;

  const EventPreviewCoverLoader({
    required this.event,
    super.key,
    this.fit = BoxFit.cover,
  });

  @override
  State<EventPreviewCoverLoader> createState() =>
      _EventPreviewCoverLoaderState();
}

class _EventPreviewCoverLoaderState extends State<EventPreviewCoverLoader> {
  final CalendarRepository _repo = CalendarRepository(ApiClient());

  List<String> _rawUrls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshFromEvent();
  }

  @override
  void didUpdateWidget(covariant EventPreviewCoverLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id ||
        !_sameImageUrls(oldWidget.event.imageUrls, widget.event.imageUrls)) {
      _refreshFromEvent();
    }
  }

  void _refreshFromEvent() {
    _rawUrls =
        newestFirstEventImageUrls(List<String>.from(widget.event.imageUrls));
    _loading = _rawUrls.isEmpty;
    if (_loading) {
      unawaited(_bootstrap());
    }
  }

  bool _sameImageUrls(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  Future<void> _bootstrap() async {
    try {
      final fromServer = await _repo.listEventImages(widget.event.id);
      if (!mounted) return;
      setState(() {
        _rawUrls = newestFirstEventImageUrls(fromServer);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get _primaryRaw => _rawUrls.isNotEmpty ? _rawUrls.first : null;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFFE8E8F0),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final raw = _primaryRaw;
    if (raw == null || raw.isEmpty) {
      return Container(
        color: const Color(0xFFE8E8F0),
        child: const Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFF9CA3AF),
        ),
      );
    }

    return EventCoverNetworkImage(
      rawUrl: raw,
      fit: widget.fit,
    );
  }
}
