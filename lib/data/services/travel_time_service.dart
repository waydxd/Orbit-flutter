// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/maps_platform_config.dart';

/// Driving duration between two addresses via Google Distance Matrix API.
abstract final class TravelTimeService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Returns driving duration in seconds, or `null` if unavailable.
  static Future<int?> drivingDurationSeconds({
    required String originAddress,
    required String destinationAddress,
  }) async {
    final o = originAddress.trim();
    final d = destinationAddress.trim();
    if (o.isEmpty || d.isEmpty) return null;

    final departureTimeSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/distancematrix/json',
      <String, String>{
        'origins': o,
        'destinations': d,
        'mode': 'driving',
        'departure_time': '$departureTimeSec',
        'key': MapsPlatformConfig.apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;
      if (data['status'] != 'OK') return null;

      final rows = data['rows'];
      if (rows is! List || rows.isEmpty) return null;

      final firstRow = rows.first;
      if (firstRow is! Map<String, dynamic>) return null;
      final elements = firstRow['elements'];
      if (elements is! List || elements.isEmpty) return null;

      final el = elements.first;
      if (el is! Map<String, dynamic>) return null;
      if (el['status'] != 'OK') return null;

      final inTraffic = el['duration_in_traffic'];
      if (inTraffic is Map<String, dynamic>) {
        final v = inTraffic['value'];
        if (v is num) return v.toInt();
      }
      final dur = el['duration'];
      if (dur is Map<String, dynamic>) {
        final v = dur['value'];
        if (v is num) return v.toInt();
      }
      return null;
    } catch (e, st) {
      debugPrint('TravelTimeService: $e\n$st');
      return null;
    }
  }
}
