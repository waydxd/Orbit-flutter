import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // TODO: Replace with your actual Google Maps API Key
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static Future<List<String>> getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$query'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => p['description'] as String)
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching place suggestions: $e');
    }
    return [];
  }
}
