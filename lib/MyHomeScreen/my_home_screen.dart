import 'dart:async';
import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/components/misc_widget.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/utils.dart';
import 'package:voyageventure/features/current_location.dart';
import '../MyLocationSearch/my_location_search.dart';
import '../components/bottom_sheet_componient.dart';

class MyHomeScreen extends StatefulWidget {
  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapsController = Completer();
  ScrollController _scrollController = ScrollController();
  DraggableScrollableController _dragableController =
      DraggableScrollableController();
  double? bottomSheetTop;
  late AnimationController _animationController;
  late Animation<double> moveAnimation;
  LatLng? currentLocation;
  bool isHaveLastSessionLocation = false;
  Future<List<LatLng>?> polylinePoints = Future.value(null);
  static CameraPosition? _initialCameraPosition;
  static const LatLng _airPort = LatLng(10.8114795, 106.6548157);
  static const LatLng _dormitory = LatLng(10.8798036, 106.8052206);
  Polyline? route;
  List<Marker> myMarker = [];

  Future<LatLng> getCurrentLocationLatLng() async {
    Position position = await getCurrentLocation();
    return LatLng(position.latitude, position.longitude);
  }

  animateToPosition(LatLng position, {double zoom = 13}) async {
    GoogleMapController controller = await _mapsController.future;
    CameraPosition cameraPosition = CameraPosition(
      target: position,
      zoom: zoom, // Change this value to your desired zoom level
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  @override
  void initState() {
    super.initState();
    if (!isHaveLastSessionLocation) {
      getCurrentLocationLatLng().then((value) {
        currentLocation = value;
        animateToPosition(currentLocation!);
      });
    }

    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    moveAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Transparent status bar
      statusBarIconBrightness: Brightness.dark,
      // Dark icons
      systemNavigationBarColor: Colors.transparent,
      // Transparent navigation bar
      systemNavigationBarIconBrightness: Brightness.dark, // Dark icons
    ));
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.black,
          //   ),
          // ),

          GoogleMap(
            initialCameraPosition: (isHaveLastSessionLocation == true)
                ? const CameraPosition(
                    target: LatLng(20, 106),
                    zoom: 13,
                  ) // Todo: last location
                : const CameraPosition(
                    target: LatLng(10.7981542, 106.6614047),
                    zoom: 13,
                  ),
            //Default location
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: Set.from(myMarker),
            onMapCreated: (GoogleMapController controller) {
              _mapsController.complete(controller);
            },
            polylines: {if (route != null) route!},
            zoomControlsEnabled: false,
            // markers: {
            //   Marker(
            //     markerId: const MarkerId('marker_1'),
            //     position: const LatLng(10.7981542, 106.6614047),
            //     infoWindow: const InfoWindow(
            //       title: 'Marker 1',
            //       snippet: '5 Star Rating',
            //     ),
            //     icon: BitmapDescriptor.defaultMarkerWithHue(
            //         BitmapDescriptor.hueViolet),
            //   ),
            //   Marker(
            //     markerId: const MarkerId('marker_2'),
            //     position: const LatLng(10.9243059, 106.8155907),
            //     infoWindow: const InfoWindow(
            //       title: 'Marker 2',
            //       snippet: '4 Star Rating',
            //     ),
            //     icon: BitmapDescriptor.defaultMarkerWithHue(
            //         BitmapDescriptor.hueViolet),
            //   ),
            // }
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            bottom: (bottomSheetTop == null)
                ? (MediaQuery.of(context).size.height * defaultBottomSheetHeight / 1000) + 10
                : bottomSheetTop! + 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  elevation: 5,
                  onPressed: () {
                    if (currentLocation != null) {
                      animateToPosition(currentLocation!);
                    }
                    getCurrentLocation().then((value) {
                      if (currentLocation !=
                          LatLng(value.latitude, value.longitude)) {
                        currentLocation =
                            LatLng(value.latitude, value.longitude);
                        animateToPosition(currentLocation!);
                        logWithTag("Location changed!", tag: "MyHomeScreen");
                      }
                    });
                    // Handle button press
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
                // Add more widgets here that you want to move with the sheet
              ],
            ),
          ),

          NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                setState(() {
                  bottomSheetTop = _dragableController.pixels;
                });
                return true;
              },
              child: DraggableScrollableSheet(
                controller: _dragableController,
                initialChildSize: defaultBottomSheetHeight / 1000,
                minChildSize: 0.15,
                maxChildSize: 1,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          primary: false,
                          controller: scrollController,
                          child: Column(children: <Widget>[
                            const Pill(),
                            LocationSearchScreen_(controller: _scrollController, sheetController: _dragableController, mapsController: _mapsController, marker: myMarker),
                            BottomSheetComponient_(controller: _scrollController),
                          ]),
                        ),
                      ),

                  );
                },
              ))
        ],
      ),
    );
  }
}
