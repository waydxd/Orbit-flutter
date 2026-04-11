import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_token_service.dart';
import '../../../data/services/txt2img_service.dart';
import '../../../config/environment.dart';
import '../../../utils/event_image_url.dart';
import '../../../utils/logger.dart';
import '../view_model/calendar_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../tasks/view/create_item_page.dart';
import 'event_suggestions_widget.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final GlobalKey<EventDetailCoverImageState> _coverImageKey =
      GlobalKey<EventDetailCoverImageState>();

  String _inferCategory(EventModel e) {
    final combined = '${e.title} ${e.description}'.toLowerCase();
    if (combined.contains('work') ||
        combined.contains('meeting') ||
        combined.contains('sync') ||
        combined.contains('office')) {
      return 'Work';
    }
    if (combined.contains('study') ||
        combined.contains('class') ||
        combined.contains('lecture') ||
        combined.contains('exam')) {
      return 'Study';
    }
    if (combined.contains('gym') ||
        combined.contains('exercise') ||
        combined.contains('workout') ||
        combined.contains('run')) {
      return 'Exercise';
    }
    if (combined.contains('personal') ||
        combined.contains('dinner') ||
        combined.contains('lunch') ||
        combined.contains('friend') ||
        combined.contains('family')) {
      return 'Personal';
    }
    return 'Event';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      color: AppColors.textPrimary,
                      onPressed: () => _showMoreOptions(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // AI-generated full-bleed cover (core /api/v1/image/... or direct txt2img) or placeholder
                          EventDetailCoverImage(
                            key: _coverImageKey,
                            event: event,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category tag (pill)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _inferCategory(event).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Location section (if present)
                                if (event.location.isNotEmpty) ...[
                                  _buildSectionLabel('LOCATION'),
                                  const SizedBox(height: 12),
                                  _buildLocationRow(event.location),
                                  const SizedBox(height: 24),
                                ],

                                // Date & Time section
                                _buildSectionLabel('DATE & TIME'),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  icon: Icons.calendar_today_rounded,
                                  text: _formatDate(event.startTime),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.access_time_rounded,
                                  text:
                                      '${_formatTimeRange(event.startTime, event.endTime)} ${_formatDuration(event.startTime, event.endTime)}',
                                ),
                                const SizedBox(height: 24),
                                _buildSectionLabel('DESCRIPTION'),
                                const SizedBox(height: 12),
                                Text(
                                  event.description.isNotEmpty
                                      ? event.description
                                      : 'No description',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: event.description.isNotEmpty
                                        ? AppColors.textSecondary
                                        : AppColors.grey400,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                EventSuggestionsWidget(event: event),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLocationRow(String location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final timeFormatter = DateFormat('h:mm a');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${timeFormatter.format(start)} - ${timeFormatter.format(end)}';
    } else {
      final dateFormatter = DateFormat('d MMM');
      return '${timeFormatter.format(start)} - ${dateFormatter.format(end)} ${timeFormatter.format(end)}';
    }
  }

  String _formatDuration(DateTime start, DateTime end) {
    final minutes = end.difference(start).inMinutes;
    if (minutes < 60) {
      return '($minutes min)';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '($hours hr $mins min)' : '($hours hr)';
  }

  Future<void> _handleDelete(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final viewModel = Provider.of<CalendarViewModel>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await viewModel.deleteEvent(widget.event.id);
      if (context.mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to delete event: $e')),
        );
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    // Important: use the page's context for navigation/dialog/provider lookups.
    // The bottom sheet's BuildContext is disposed after closing the sheet.
    final pageContext = context;
    showModalBottomSheet(
      context: pageContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Edit',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  pageContext,
                  MaterialPageRoute(
                    builder: (context) => CreateItemPage(
                      initialIsEvent: true,
                      editEvent: widget.event,
                    ),
                  ),
                ).then((result) {
                  if (result == true && pageContext.mounted) {
                    Navigator.pop(pageContext);
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
              ),
              title: const Text(
                'Regenerate image',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _coverImageKey.currentState?.regenerateCover(pageContext);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Upload image',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _coverImageKey.currentState?.pickAndUploadCover(pageContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleDelete(pageContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 1:1 hero: prefers backend-stored images, then generates once and uploads to `POST /events/{id}/images`.
class EventDetailCoverImage extends StatefulWidget {
  const EventDetailCoverImage({required this.event, super.key});

  final EventModel event;

  @override
  EventDetailCoverImageState createState() => EventDetailCoverImageState();
}

class EventDetailCoverImageState extends State<EventDetailCoverImage> {
  final Txt2ImgService _service = Txt2ImgService();
  final CalendarRepository _calendarRepo = CalendarRepository(ApiClient());

  bool _loading = true;
  Txt2ImgCoverResult? _result;

  /// URLs from event model, `GET /events/{id}/images`, or after upload from this page.
  List<String> _displayUrls = [];
  int _coverRetryKey = 0;

  /// API returns images in append order (oldest → newest). Hero uses [first].
  static List<String> _newestFirstUrls(List<String> urls) {
    if (urls.length <= 1) return List<String>.from(urls);
    return urls.reversed.toList();
  }

  Future<List<String>> _refetchDisplayUrlsFromBackend({
    required List<String> fallbackIfEmpty,
  }) async {
    try {
      final fresh = await _calendarRepo.listEventImages(widget.event.id);
      if (fresh.isNotEmpty) return _newestFirstUrls(fresh);
    } catch (e) {
      Logger.warningWithTag('EventDetailCover', 'refetch images: $e');
    }
    return List<String>.from(fallbackIfEmpty);
  }

  void _scheduleCalendarRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await Provider.of<CalendarViewModel>(context, listen: false).fetchAll(
          userId: widget.event.userId,
          eventRangeAnchor: widget.event.startTime,
          showLoading: false,
        );
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    _displayUrls = _newestFirstUrls(List<String>.from(widget.event.imageUrls));
    if (_displayUrls.isNotEmpty) {
      _loading = false;
    } else {
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    try {
      final fromServer = await _calendarRepo.listEventImages(widget.event.id);
      if (!mounted) return;
      if (fromServer.isNotEmpty) {
        setState(() {
          _displayUrls = _newestFirstUrls(fromServer);
          _loading = false;
        });
        return;
      }
    } catch (e) {
      Logger.warningWithTag('EventDetailCover', 'listEventImages: $e');
    }
    if (!mounted) return;
    if (!EnvironmentConfig.shouldClientAttemptTxt2Img) {
      setState(() => _loading = false);
      return;
    }
    await _generateAndUpload();
  }

  Future<void> _generateAndUpload() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    final r = await _service.requestCoverUrl(widget.event);
    if (!mounted) return;
    if (r.isSuccess && r.url != null) {
      try {
        final backendUrl = await _calendarRepo.uploadEventCoverFromGeneratedUrl(
          eventId: widget.event.id,
          imageUrl: r.url!,
          declaredContentType: r.contentType,
        );
        if (!mounted) return;
        final synced = await _refetchDisplayUrlsFromBackend(
          fallbackIfEmpty: [backendUrl],
        );
        if (!mounted) return;
        setState(() {
          _displayUrls = synced;
          _result = null;
          _loading = false;
        });
        _scheduleCalendarRefresh();
        return;
      } catch (e, st) {
        Logger.errorWithTag(
          'EventDetailCover',
          'Upload cover failed, showing temporary URL: $e\n$st',
        );
        if (!mounted) return;
        setState(() {
          _result = r;
          _loading = false;
        });
        return;
      }
    }
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  /// Forces a new txt2img request and upload (skips loading existing server images).
  Future<void> regenerateCover(BuildContext messengerContext) async {
    if (!EnvironmentConfig.shouldClientAttemptTxt2Img) {
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Image generation is disabled. Enable txt2img or set TXT2IMG_BASE_URL.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _displayUrls = [];
      _result = null;
      _loading = true;
      _coverRetryKey++;
    });
    await _generateAndUpload();
    if (!mounted) return;
    if (!messengerContext.mounted) return;
    final ok = _displayUrls.isNotEmpty ||
        (_result?.isSuccess == true && _result!.url != null);
    if (ok) {
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        const SnackBar(content: Text('Cover regenerated')),
      );
    } else if (_result != null &&
        !_result!.skipped &&
        _result!.errorMessage != null &&
        _result!.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        SnackBar(content: Text(_result!.errorMessage!)),
      );
    }
  }

  /// Picks an image from gallery or camera and uploads via `POST /events/{id}/images`.
  Future<void> pickAndUploadCover(BuildContext messengerContext) async {
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: messengerContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;

    setState(() {
      _displayUrls = [];
      _result = null;
      _loading = true;
      _coverRetryKey++;
    });

    try {
      final bytes = await file.readAsBytes();
      final name = file.name.trim().isNotEmpty ? file.name : 'upload.jpg';
      final url = await _calendarRepo.uploadEventImageFromBytes(
        eventId: widget.event.id,
        bytes: bytes,
        filename: name,
      );
      if (!mounted) return;
      final synced = await _refetchDisplayUrlsFromBackend(
        fallbackIfEmpty: [url],
      );
      if (!mounted) return;
      setState(() {
        _displayUrls = synced;
        _result = null;
        _loading = false;
      });
      _scheduleCalendarRefresh();
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          const SnackBar(content: Text('Image uploaded')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      try {
        final fromServer = await _calendarRepo.listEventImages(widget.event.id);
        if (!mounted) return;
        if (fromServer.isNotEmpty) {
          setState(() => _displayUrls = _newestFirstUrls(fromServer));
        }
      } catch (_) {}
    }
  }

  Future<Map<String, String>?> _headersFor(String absoluteUrl) async {
    if (!eventImageUrlRequiresAuth(absoluteUrl)) return {};
    final token = await AuthTokenService.getAccessToken();
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Widget _cachedCover(String rawUrl) {
    final absolute = resolveEventImageUrl(rawUrl);
    return FutureBuilder<Map<String, String>?>(
      key: ValueKey<String>('cover_${rawUrl}_$_coverRetryKey'),
      future: _headersFor(absolute),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: AppColors.grey100,
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
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, u) => Container(
            color: AppColors.grey100,
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, u, error) =>
              _errorBody('Could not load image'),
        );
      },
    );
  }

  Future<void> _retry() async {
    if (_displayUrls.isNotEmpty) {
      setState(() => _coverRetryKey++);
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: _buildInner(),
    );
  }

  Widget _buildInner() {
    if (_displayUrls.isNotEmpty) {
      return _cachedCover(_displayUrls.first);
    }

    if (_loading) {
      return Container(
        color: AppColors.grey100,
        child: const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final r = _result;
    if (r == null) {
      return _staticPlaceholder();
    }

    if (r.isSuccess && r.url != null) {
      return _cachedCover(r.url!);
    }

    if (r.skipped) {
      return _staticPlaceholder();
    }

    return _errorBody(r.errorMessage ?? 'Could not generate image');
  }

  Widget _staticPlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.grey400,
        ),
      ),
    );
  }

  Widget _errorBody(String message) {
    return Container(
      color: AppColors.grey100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 40,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
