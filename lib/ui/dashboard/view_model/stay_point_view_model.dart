import 'package:flutter/foundation.dart';
import '../../../modules/location_tracking/models/stay_point.dart';
import '../../../modules/location_tracking/storage/location_storage.dart';

class StayPointViewModel extends ChangeNotifier {
  static const double _hkustLat = 22.3368;
  static const double _hkustLon = 114.2636;

  List<StayPoint> _stayPoints = [];
  bool _isLoading = false;
  String? _error;

  List<StayPoint> get stayPoints => _stayPoints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _stayPoints.isEmpty && !_isLoading && !hasError;

  Future<void> loadStayPoints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stayPoints = LocationStorage.getAllStayPoints()
        ..sort((a, b) => b.arrivalTime.compareTo(a.arrivalTime));

      if (_stayPoints.isEmpty) {
        _stayPoints = [_buildDemoHkustStayPoint()];
      }
    } catch (e) {
      _error = 'Failed to load locations: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  StayPoint _buildDemoHkustStayPoint() {
    final now = DateTime.now();
    final arrival = now.subtract(const Duration(hours: 3, minutes: 30));
    return StayPoint(
      id: 'demo_hkust_significant_location',
      centroidLat: _hkustLat,
      centroidLon: _hkustLon,
      arrivalTime: arrival,
      departureTime: now,
      dwellDurationMinutes: now.difference(arrival).inMinutes,
      label: 'HKUST',
    );
  }
}
