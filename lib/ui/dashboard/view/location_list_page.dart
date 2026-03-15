import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../../data/models/event_model.dart';
import 'location_detail_page.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({super.key});

  @override
  State<LocationListPage> createState() => _LocationListPageState();
}

class _LocationListPageState extends State<LocationListPage> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(22.3193, 114.1694);
  final Map<String, LatLng> _geocodedLocations = {};
  bool _isGeocoding = true;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geocodeAllEventLocations();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {}
  }

  Future<void> _geocodeAllEventLocations() async {
    final vm = Provider.of<CalendarViewModel>(context, listen: false);
    final uniqueLocations = <String>{};
    for (final event in vm.events) {
      if (event.location.isNotEmpty) uniqueLocations.add(event.location);
    }

    if (uniqueLocations.isEmpty) {
      if (mounted) setState(() => _isGeocoding = false);
      return;
    }

    await Future.wait(
      uniqueLocations.map((loc) async {
        try {
          final results = await locationFromAddress(loc);
          if (results.isNotEmpty && mounted) {
            _geocodedLocations[loc] =
                LatLng(results.first.latitude, results.first.longitude);
          }
        } catch (_) {}
      }),
    );

    if (mounted) {
      setState(() => _isGeocoding = false);
      _fitAllLocations();
    }
  }

  void _fitAllLocations() {
    if (_geocodedLocations.isEmpty || _mapController == null) return;

    final allPoints = [
      _currentPosition,
      ..._geocodedLocations.values,
    ];

    if (allPoints.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, 14.0),
      );
      return;
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLon = allPoints.first.longitude;
    double maxLon = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLon),
          northeast: LatLng(maxLat, maxLon),
        ),
        72.0,
      ),
    );
  }

  void _animateToLocation(String locationName) {
    final coords = _geocodedLocations[locationName];
    if (coords == null || _mapController == null) return;
    setState(() => _selectedLocation = locationName);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(coords, 15.0),
    );
  }

  Set<Marker> _buildMarkers(Map<String, int> locationCounts) {
    return _geocodedLocations.entries.map((entry) {
      final isSelected = _selectedLocation == entry.key;
      return Marker(
        markerId: MarkerId(entry.key),
        position: entry.value,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueRose,
        ),
        infoWindow: InfoWindow(
          title: entry.key,
          snippet:
              '${locationCounts[entry.key] ?? 0} event${(locationCounts[entry.key] ?? 0) != 1 ? 's' : ''}',
        ),
        onTap: () => setState(() => _selectedLocation = entry.key),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CalendarViewModel>(
        builder: (context, vm, _) {
          final Map<String, int> locationCounts = {};
          final Map<String, List<EventModel>> locationEvents = {};
          for (final event in vm.events) {
            if (event.location.isNotEmpty) {
              locationCounts[event.location] =
                  (locationCounts[event.location] ?? 0) + 1;
              locationEvents
                  .putIfAbsent(event.location, () => [])
                  .add(event);
            }
          }

          final sortedLocations = locationCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Stack(
            children: [
              // Full-screen map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14.0,
                ),
                markers: _buildMarkers(locationCounts),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
                onTap: (_) => setState(() => _selectedLocation = null),
              ),

              // Top bar — matches SignificantLocationsPage
              _buildTopBar(),

              // Geocoding loading pill
              if (_isGeocoding)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading locations…',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Draggable card sheet — matches other pages
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.12,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [0.35, 0.85],
                builder: (sheetCtx, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _buildSheetContent(
                      scrollController,
                      sortedLocations,
                      locationEvents,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
              _CircleIconButton(
                icon: Icons.my_location,
                onTap: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheet content ─────────────────────────────────────────────────────

  Widget _buildSheetContent(
    ScrollController controller,
    List<MapEntry<String, int>> sortedLocations,
    Map<String, List<EventModel>> locationEvents,
  ) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        // Drag handle
        SliverToBoxAdapter(child: _buildDragHandle()),

        if (sortedLocations.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_outlined,
                    size: 48, color: AppColors.grey400),
                SizedBox(height: 12),
                Text(
                  'No event locations yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add locations to your events\nto see them here',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${sortedLocations.length} Location${sortedLocations.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_geocodedLocations.isNotEmpty)
                    GestureDetector(
                      onTap: _fitAllLocations,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_out_map,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Show All',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Location cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final entry = sortedLocations[index];
                final events = locationEvents[entry.key] ?? [];
                return _buildLocationCard(
                    ctx, entry.key, entry.value, events);
              },
              childCount: sortedLocations.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    String locationName,
    int count,
    List<EventModel> events,
  ) {
    events.sort((a, b) => b.startTime.compareTo(a.startTime));
    final latest = events.isNotEmpty ? events.first : null;
    final isSelected = _selectedLocation == locationName;

    return GestureDetector(
      onTap: () {
        _animateToLocation(locationName);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LocationDetailPage(locationName: locationName),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: AppColors.grey200, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_outlined,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (latest != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Latest: ${latest.title}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (latest != null) ...[
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, h:mm a')
                              .format(latest.startTime),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count event${count != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
