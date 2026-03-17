// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract final class LocationService {
  // Google Maps API Key
  static const String _apiKey = 'AIzaSyDY_Fu5bhGPf2ZHXZF3pCxOHxnbv9ymnVA';

  static Future<List<String>> getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$query'
            '&key=$_apiKey');

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
      debugPrint('Error fetching place suggestions: $e');
    }
    return [];
  }
}
