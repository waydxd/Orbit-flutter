import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/gps_fix.dart';
import '../models/stay_point.dart';

class StayPointDetector {
  final double distanceThresholdMeters;
  final int minDwellTimeMinutes;

  StayPointDetector({
    this.distanceThresholdMeters = 100.0,
    this.minDwellTimeMinutes = 10,
  });

  /// Processes a list of GPS fixes and returns a tuple:
  /// (List of detected StayPoints, Keys of fixes that should be removed/processed)
  (List<StayPoint>, List<dynamic>) detect(
      List<GpsFix> fixes, List<dynamic> keys) {
    if (fixes.isEmpty) return (<StayPoint>[], <dynamic>[]);

    List<StayPoint> stayPoints = [];
    List<dynamic> processedKeys = [];

    int i = 0;
    while (i < fixes.length) {
      int j = i + 1;

      while (j < fixes.length) {
        double distance = Geolocator.distanceBetween(
          fixes[i].latitude,
          fixes[i].longitude,
          fixes[j].latitude,
          fixes[j].longitude,
        );

        if (distance > distanceThresholdMeters) {
          break;
        }
        j++;
      }

      // We've found the maximal window [i, j-1] where all points are within
      // distanceThresholdMeters of fixes[i].
      // Now check if the duration meets the requirement.
      final duration = fixes[j - 1].timestamp.difference(fixes[i].timestamp);

      if (duration.inMinutes >= minDwellTimeMinutes) {
        // Calculate centroid
        double sumLat = 0.0;
        double sumLon = 0.0;
        for (int k = i; k < j; k++) {
          sumLat += fixes[k].latitude;
          sumLon += fixes[k].longitude;
        }
        int count = j - i;
        double centroidLat = sumLat / count;
        double centroidLon = sumLon / count;

        final stayPoint = StayPoint(
          id: const Uuid().v4(),
          centroidLat: centroidLat,
          centroidLon: centroidLon,
          arrivalTime: fixes[i].timestamp,
          departureTime: fixes[j - 1].timestamp,
          dwellDurationMinutes: duration.inMinutes,
        );

        stayPoints.add(stayPoint);

        // Mark these fixes as processed so we can delete them
        for (int k = i; k < j; k++) {
          processedKeys.add(keys[k]);
        }

        // Move `i` to `j` to start searching for the next stay point
        i = j;
      } else {
        // Not a stay point. If `j` reached the end, it means the current
        // window is open-ended. We shouldn't discard these points yet because
        // future points might keep the user in the same location and satisfy
        // the time requirement.
        if (j == fixes.length) {
          break;
        } else {
          // If `j < fixes.length`, the user has moved away before `minDwellTimeMinutes`.
          // This means `fixes[i]` is not part of a stay point.
          // Discard `fixes[i]` and advance `i`.
          processedKeys.add(keys[i]);
          i++;
        }
      }
    }

    return (stayPoints, processedKeys);
  }
}
