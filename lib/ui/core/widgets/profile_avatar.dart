import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../utils/event_image_url.dart';
import '../themes/app_colors.dart';

/// Circular avatar: network image when [rawProfilePictureUrl] is set, else initials.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.initials,
    this.localImageBytes,
    this.rawProfilePictureUrl,
    this.cacheBuster,
    this.size = 64,
    super.key,
  });

  final String initials;
  final Uint8List? localImageBytes;
  final String? rawProfilePictureUrl;
  final int? cacheBuster;
  final double size;

  static const List<Color> _placeholderGradient = [
    Color(0xFF8E86FF),
    Color(0xFF6B63F6),
  ];

  @override
  Widget build(BuildContext context) {
    if (localImageBytes != null && localImageBytes!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.memory(
            localImageBytes!,
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        ),
      );
    }
    final raw = rawProfilePictureUrl?.trim() ?? '';
    if (raw.isEmpty) {
      return _initialsBody(context);
    }
    final absolute = resolveEventImageUrl(raw);
    if (absolute.isEmpty) {
      return _initialsBody(context);
    }
    final uri = Uri.parse(absolute);
    final effectiveUri = cacheBuster == null
        ? uri
        : uri.replace(
            queryParameters: {
              ...uri.queryParameters,
              'v': cacheBuster.toString(),
            },
          );
    final effectiveUrl = effectiveUri.toString();

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<Map<String, String>?>(
          future: eventImageRequestHeaders(effectiveUrl),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return _loadingBody();
            }
            final h = snap.data;
            return CachedNetworkImage(
              imageUrl: effectiveUrl,
              httpHeaders: (h == null || h.isEmpty) ? null : h,
              fit: BoxFit.cover,
              width: size,
              height: size,
              placeholder: (context, url) => _loadingBody(),
              errorWidget: (context, url, error) => _initialsBody(context),
            );
          },
        ),
      ),
    );
  }

  Widget _loadingBody() {
    return Container(
      width: size,
      height: size,
      color: AppColors.grey100,
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.35,
        height: size * 0.35,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _initialsBody(BuildContext context) {
    final display = initials.isNotEmpty ? initials : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _placeholderGradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        display,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.35,
            ),
      ),
    );
  }
}
