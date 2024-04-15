import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


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

  final List<Marker> myMarker = [];
  final List<Marker> markerList = [
    const Marker(markerId: MarkerId("First"),
    position: LatLng(10.7981542, 106.6614147),
    infoWindow: InfoWindow(title: "First Marker"),
    )
    ,
    const Marker(markerId: MarkerId("Second"),
    position: LatLng(10.9243059,106.8155907),
    infoWindow: InfoWindow(title: "Second Marker"),
    )
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myMarker.addAll(markerList);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          mapType: MapType.normal,
          markers: Set.from(myMarker),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          zoomControlsEnabled: false,
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
