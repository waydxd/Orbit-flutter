import 'package:flutter/foundation.dart';
import '../../../modules/location_tracking/models/stay_point.dart';
import '../../../modules/location_tracking/storage/location_storage.dart';

class StayPointViewModel extends ChangeNotifier {
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
    } catch (e) {
      _error = 'Failed to load locations: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
