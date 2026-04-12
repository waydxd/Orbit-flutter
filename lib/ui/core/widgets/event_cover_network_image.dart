import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../utils/event_image_url.dart';
import '../themes/app_colors.dart';

/// Loads an event image the same way as [EventDetailCoverImage]: resolve relative
/// paths against the API base URL and attach Bearer headers when required.
class EventCoverNetworkImage extends StatelessWidget {
  final String rawUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const EventCoverNetworkImage({
    required this.rawUrl,
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final absolute = resolveEventImageUrl(rawUrl);
    if (absolute.isEmpty) {
      return _errorBody();
    }

    return FutureBuilder<Map<String, String>?>(
      future: eventImageRequestHeaders(absolute),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: AppColors.grey100,
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final h = snap.data;
        return CachedNetworkImage(
          imageUrl: absolute,
          httpHeaders: (h == null || h.isEmpty) ? null : h,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, u) => Container(
            color: AppColors.grey100,
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, u, error) => _errorBody(),
        );
      },
    );
  }

  Widget _errorBody() {
    return Container(
      color: AppColors.grey100,
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.grey400),
      ),
    );
  }
}
