import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../../data/models/event_model.dart';
import '../view_model/stay_point_view_model.dart';
import '../widgets/significant_location_card.dart';
import '../../../modules/location_tracking/models/stay_point.dart';
import 'location_detail_page.dart';

class SignificantLocationsPage extends StatefulWidget {
  const SignificantLocationsPage({super.key});

  @override
  State<SignificantLocationsPage> createState() =>
      _SignificantLocationsPageState();
}

class _SignificantLocationsPageState extends State<SignificantLocationsPage> {
  GoogleMapController? _mapController;
  int? _selectedIndex;
  bool _hasInitialFit = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const LatLng _defaultCenter = LatLng(22.3193, 114.1694);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Current location ──────────────────────────────────────────────────

  Future<void> _centerOnMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not determine current location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── StayPoint map helpers ─────────────────────────────────────────────

  void _onStayPointCardTapped(int index, StayPoint sp) {
    setState(() => _selectedIndex = index);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(sp.centroidLat, sp.centroidLon),
        15.0,
      ),
    );
  }

  void _fitAllMarkers(List<StayPoint> stayPoints) {
    if (stayPoints.isEmpty || _mapController == null) return;

    if (stayPoints.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(stayPoints.first.centroidLat, stayPoints.first.centroidLon),
          15.0,
        ),
      );
      return;
    }

    double minLat = stayPoints.first.centroidLat;
    double maxLat = stayPoints.first.centroidLat;
    double minLon = stayPoints.first.centroidLon;
    double maxLon = stayPoints.first.centroidLon;

    for (final sp in stayPoints) {
      if (sp.centroidLat < minLat) minLat = sp.centroidLat;
      if (sp.centroidLat > maxLat) maxLat = sp.centroidLat;
      if (sp.centroidLon < minLon) minLon = sp.centroidLon;
      if (sp.centroidLon > maxLon) maxLon = sp.centroidLon;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLon),
          northeast: LatLng(maxLat, maxLon),
        ),
        64.0,
      ),
    );
  }

  Set<Marker> _buildMarkers(List<StayPoint> stayPoints) {
    return stayPoints.asMap().entries.map((entry) {
      final i = entry.key;
      final sp = entry.value;
      return Marker(
        markerId: MarkerId(sp.id),
        position: LatLng(sp.centroidLat, sp.centroidLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedIndex == i
              ? BitmapDescriptor.hueViolet
              : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: sp.label ?? 'Significant Location',
          snippet:
              SignificantLocationCard.formatDuration(sp.dwellDurationMinutes),
        ),
        onTap: () => _onStayPointCardTapped(i, sp),
      );
    }).toSet();
  }

  void _showStayPointDetail(BuildContext context, StayPoint sp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StayPointDetailSheet(stayPoint: sp),
    );
  }

  // ── Event locations helper ────────────────────────────────────────────

  List<MapEntry<String, List<EventModel>>> _extractEventLocations(
      CalendarViewModel calendarVm) {
    final Map<String, List<EventModel>> grouped = {};
    for (final event in calendarVm.events) {
      if (event.location.isNotEmpty) {
        grouped.putIfAbsent(event.location, () => []).add(event);
      }
    }
    return grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StayPointViewModel()..loadStayPoints(),
      child: Scaffold(
        body: Consumer<StayPointViewModel>(
          builder: (context, vm, _) {
            final calendarVm = Provider.of<CalendarViewModel>(context);
            final stayPoints = vm.stayPoints;
            final eventLocations = _extractEventLocations(calendarVm);

            if (!_hasInitialFit &&
                stayPoints.isNotEmpty &&
                _mapController != null) {
              _hasInitialFit = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitAllMarkers(stayPoints);
              });
            }

            final initialCenter = stayPoints.isNotEmpty
                ? LatLng(
                    stayPoints.first.centroidLat, stayPoints.first.centroidLon)
                : _defaultCenter;

            return Stack(
              children: [
                // Full-screen map with live blue dot
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: initialCenter, zoom: 12.0),
                  markers: _buildMarkers(stayPoints),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (stayPoints.isNotEmpty) {
                      _hasInitialFit = true;
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) _fitAllMarkers(stayPoints);
                      });
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),

                // Top bar: back | my-location + refresh
                _buildTopBar(context, vm),

                // Floating card sheet
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
                        vm,
                        scrollController,
                        stayPoints,
                        eventLocations,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, StayPointViewModel vm) {
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
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.my_location,
                    onTap: _centerOnMyLocation,
                  ),
                  const SizedBox(width: 8),
                  _CircleIconButton(
                    icon: Icons.refresh,
                    onTap: () {
                      vm.loadStayPoints();
                      setState(() {
                        _selectedIndex = null;
                        _hasInitialFit = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheet content ─────────────────────────────────────────────────────

  List<StayPoint> _filterStayPoints(List<StayPoint> stayPoints) {
    if (_searchQuery.isEmpty) return stayPoints;
    return stayPoints
        .where((sp) => (sp.label ?? 'Significant Location')
            .toLowerCase()
            .contains(_searchQuery))
        .toList();
  }

  List<MapEntry<String, List<EventModel>>> _filterEventLocations(
      List<MapEntry<String, List<EventModel>>> eventLocations) {
    if (_searchQuery.isEmpty) return eventLocations;
    return eventLocations
        .where((e) => e.key.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Widget _buildSheetContent(
    StayPointViewModel vm,
    ScrollController controller,
    List<StayPoint> stayPoints,
    List<MapEntry<String, List<EventModel>>> eventLocations,
  ) {
    final filteredStayPoints = _filterStayPoints(stayPoints);
    final filteredEventLocations = _filterEventLocations(eventLocations);
    final totalCount =
        filteredStayPoints.length + filteredEventLocations.length;
    final allEmpty = totalCount == 0 && !vm.isLoading && !vm.hasError;
    final hasDataButNoSearchResults = totalCount == 0 &&
        (stayPoints.isNotEmpty || eventLocations.isNotEmpty) &&
        _searchQuery.isNotEmpty;

    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(child: _buildDragHandle()),
        if (vm.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingWidget(message: 'Loading locations…'),
          )
        else if (vm.hasError)
          SliverFillRemaining(
            hasScrollBody: false,
            child:
                AppErrorWidget(message: vm.error!, onRetry: vm.loadStayPoints),
          )
        else if (allEmpty && !hasDataButNoSearchResults)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else ...[
          // Header
          SliverToBoxAdapter(
            child: _buildSheetHeader(totalCount, filteredStayPoints),
          ),

          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),

          if (hasDataButNoSearchResults)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildNoSearchResultsState(),
            )
          else ...[
            // ── Significant Locations (StayPoints) ──
            if (filteredStayPoints.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Significant Locations',
                  filteredStayPoints.length,
                  Icons.location_on,
                  AppColors.primary,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final sp = filteredStayPoints[index];
                    final originalIndex =
                        stayPoints.indexWhere((p) => p.id == sp.id);
                    return SignificantLocationCard(
                      stayPoint: sp,
                      isSelected: _selectedIndex == originalIndex,
                      onTap: () => _onStayPointCardTapped(originalIndex, sp),
                      onLongPress: () => _showStayPointDetail(ctx, sp),
                    );
                  },
                  childCount: filteredStayPoints.length,
                ),
              ),
            ],

            // ── Event Locations ──
            if (filteredEventLocations.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Event Locations',
                  filteredEventLocations.length,
                  Icons.event_outlined,
                  AppColors.primary,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final entry = filteredEventLocations[index];
                    return _buildEventLocationCard(ctx, entry.key, entry.value);
                  },
                  childCount: filteredEventLocations.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ],
    );
  }

  // ── Sheet sub-widgets ─────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search locations...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                },
                child: Icon(Icons.close, size: 18, color: AppColors.grey400),
              )
            else
              Icon(Icons.search, size: 20, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

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

  Widget _buildSheetHeader(int totalCount, List<StayPoint> stayPoints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          const Spacer(),
          if (stayPoints.isNotEmpty)
            GestureDetector(
              onTap: () => _fitAllMarkers(stayPoints),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_out_map, size: 16, color: AppColors.primary),
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
    );
  }

  Widget _buildSectionTitle(String title, int count, IconData icon, Color color,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildEventLocationCard(
    BuildContext context,
    String locationName,
    List<EventModel> events,
  ) {
    events.sort((a, b) => b.startTime.compareTo(a.startTime));
    final latest = events.first;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationDetailPage(locationName: locationName),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200, width: 0.5),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_outlined,
                  color: AppColors.primary, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    'Latest: ${latest.title}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(latest.startTime),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${events.length} event${events.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          const Text(
            'No locations match your search',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_off_outlined, size: 48, color: AppColors.grey400),
        SizedBox(height: 12),
        Text(
          'No locations yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Locations will appear from your events\nand as you move around',
          style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Shared circle button ──────────────────────────────────────────────────

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

// ── StayPoint detail sheet ────────────────────────────────────────────────

class _StayPointDetailSheet extends StatelessWidget {
  final StayPoint stayPoint;

  const _StayPointDetailSheet({required this.stayPoint});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_on,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stayPoint.label ?? 'Significant Location',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SignificantLocationCard.formatCoordinates(
                          stayPoint.centroidLat,
                          stayPoint.centroidLon,
                        ),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.login_rounded,
              label: 'Arrival',
              value: DateFormat('MMM d, yyyy • h:mm a')
                  .format(stayPoint.arrivalTime),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.logout_rounded,
              label: 'Departure',
              value: DateFormat('MMM d, yyyy • h:mm a')
                  .format(stayPoint.departureTime),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Dwell Duration',
              value: SignificantLocationCard.formatDuration(
                  stayPoint.dwellDurationMinutes),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
