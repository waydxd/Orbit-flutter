import '../../../data/services/api_client.dart';
import '../../../data/services/local_storage_service.dart';
import '../models/stay_point.dart';

class LocationApiService {
  static final ApiClient _apiClient = ApiClient();

  static Future<void> syncStayPoint(StayPoint stayPoint) async {
    try {
      // Get current user ID from secure storage or preferences if available
      // Assuming user_id is stored in secure storage
      final userId = await LocalStorageService.getSecure('user_id') ?? 'unknown_user';

      final data = {
        'user_id': userId,
        'longitude': stayPoint.centroidLon,
        'latitude': stayPoint.centroidLat,
      };

      // Assuming the endpoint is /locations
      await _apiClient.post('/locations', data: data);
      print('Successfully synced stay point to backend');
    } catch (e) {
      print('Failed to sync stay point: $e');
    }
  }
}
