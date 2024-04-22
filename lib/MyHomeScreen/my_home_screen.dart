import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/MySearchBar/my_search_bar.dart';
import 'package:http/http.dart' as http;
import 'package:voyageventure/utils.dart';


class MyHomeScreen extends StatefulWidget {

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {

  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(10.7981542, 106.6614047),
    zoom: 12,
  );
  static const LatLng _airPort = LatLng(10.8114795,106.6548157);
  static const LatLng _dormitory = LatLng(10.8798036,106.8052206);
  Polyline? route;

  Future<void> computeRoutes(LatLng from, LatLng to) async {
    final response = await http.post(
      Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
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
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'departureTime': DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
        'computeAlternativeRoutes': false,
        'routeModifiers': {
          'avoidTolls': false,
          'avoidHighways': false,
          'avoidFerries': false,
        },
        'languageCode': 'VI',
        'units': 'Metric',
      }),
    );
    logWithTab(response.body.toString(), tag: 'computeRoutes');
    if (response.statusCode == 200) {
      Map<String, dynamic> values = jsonDecode(response.body);
      String encodedPolyline = values['routes'][0]['polyline']['encodedPolyline'];
      List<LatLng> polylinePoints = decodePolyline(encodedPolyline);

      setState(() {
        route = Polyline(
          polylineId: PolylineId("route"),
          color: Colors.blue,
          points: polylinePoints,
        );
      });

    } else {
      throw Exception('Failed to compute routes');
    }
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
  // final List<Marker> myMarker = [];
  // final List<Marker> markerList = [
  //   const Marker(markerId: MarkerId("First"),
  //   position: LatLng(10.7981542, 106.6614147),
  //   infoWindow: InfoWindow(title: "First Marker"),
  //   )
  //   ,
  //   const Marker(markerId: MarkerId("Second"),
  //   position: LatLng(10.9243059,106.8155907),
  //   infoWindow: InfoWindow(title: "Second Marker"),
  //   )
  // ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    computeRoutes(_airPort, _dormitory);
    //myMarker.addAll(markerList);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MySearchBar(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          mapType: MapType.normal,
          myLocationEnabled: true,
          //markers: Set.from(myMarker),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
            polylines: {
              if (route != null) route!
            },
          zoomControlsEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('marker_1'),
              position: const LatLng(10.7981542, 106.6614047),
              infoWindow: const InfoWindow(
                title: 'Marker 1',
                snippet: '5 Star Rating',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ),
            Marker(
              markerId: const MarkerId('marker_2'),
              position: const LatLng(10.9243059, 106.8155907),
              infoWindow: const InfoWindow(
                title: 'Marker 2',
                snippet: '4 Star Rating',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ),
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
            (CameraUpdate.newCameraPosition(_initialCameraPosition ));
        },
        child: const Icon(Icons.my_location_rounded),
      )
    );
  }

}
