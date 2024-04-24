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

import '../models/route_calculate.dart';


class MyHomeScreen extends StatefulWidget {

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {

  final Completer<GoogleMapController> _controller = Completer();

  Future<List<LatLng>?> polylinePoints = Future.value(null);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(10.7981542, 106.6614047),
    zoom: 12,
  );

  static const LatLng _airPort = LatLng(10.8114795,106.6548157);
  static const LatLng _dormitory = LatLng(10.8798036,106.8052206);
  Polyline? route;
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
      body: Stack(
        children: <Widget>[
          GoogleMap(
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
          DraggableScrollableSheet(
            initialChildSize: 0.1, // initial size of the sheet, 10% of screen height
            minChildSize: 0.1, // minimum size of the sheet, 10% of screen height
            maxChildSize: 1.0, // maximum size of the sheet, 100% of screen height
            builder: (BuildContext context, ScrollController scrollController) {
              return ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 8.0),
                          height: 4.0,
                          width: 40.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: 2,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              title: Text('Item $index'),
                              onTap: () {},
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          polylinePoints = computeRoutes(from: _airPort,to: _dormitory);
          polylinePoints.then((value) {
            setState(() {
              if (value != null) {
                route = Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.green,
                  points: value,
                  width: 5,
                );
              }
            });
          });
            //(CameraUpdate.newCameraPosition(_initialCameraPosition ));
        },
        child: const Icon(Icons.my_location_rounded),
      )
    );
  }

}
