import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/MySearchBar/my_search_bar.dart';


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
