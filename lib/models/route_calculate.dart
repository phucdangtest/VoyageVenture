import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:voyageventure/models/route_calculate_response.dart';
import '../utils.dart';

Future<List<LatLng>?> computeRoutes({
  required LatLng from,
  required LatLng to,
  String? departureTime,
  bool computeAlternativeRoutes = false,
  bool avoidTolls = false,
  bool avoidHighways = false,
  bool avoidFerries = false,
  String travelMode = "DRIVE",
  String routingPreference = "TRAFFIC_AWARE",
  String languageCode = "VI",
  String units = "Metric",
}) async {
  logWithTab('computeRoutes', tag: 'computeRoutes');

  departureTime ??= DateTime.now().add(const Duration(minutes: 5)).toUtc().toIso8601String();
  final response = await http.post(
    Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': dotenv.env['MAPS_API_KEY1']!,
      //'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
      'X-Goog-FieldMask': '*',
    },
    body: jsonEncode(<String, dynamic>{
      'origin': {
        'location': {
          'latLng': {
            'latitude': from.latitude,
            'longitude': from.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': to.latitude,
            'longitude': to.longitude,
          },
        },
      },
      'travelMode': travelMode,
      'routingPreference': routingPreference,
      'departureTime': departureTime,
      'computeAlternativeRoutes': computeAlternativeRoutes,
      'routeModifiers': {
        'avoidTolls': avoidTolls,
        'avoidHighways': avoidHighways,
        'avoidFerries': avoidFerries,
      },
      'languageCode': languageCode,
      'units': units,
    }),
  );

  logWithTab(response.body.toString(), tag: 'computeRoutes');

  if (response.statusCode == 200) {
    //Map<String, dynamic> values = jsonDecode(response.body);
    //String encodedPolyline = values['routes'][0]['polyline']['encodedPolyline'];
    final parsed = json.decode(response.body).cast<String, dynamic>();
    RouteResponse_ routeResponse = RouteResponse_.fromJson(parsed);
    Route_ route = routeResponse.routes[0];
    List<LatLng> polylinePoints =
        decodePolyline(route.legs[0].polyline.encodedPolyline);
    logWithTab(route.toString(), tag: 'computeRoutes');
    return polylinePoints;
  }
  print("Error: ${response.body}");
  return null;
}

List<LatLng> decodePolyline(String encoded) {
  List<LatLng> points = <LatLng>[];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    LatLng p = LatLng(lat / 1E5, lng / 1E5);
    points.add(p);
  }

  return points;
}
