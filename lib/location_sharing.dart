import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/features/current_location.dart';

class LocationSharing extends StatefulWidget {
  const LocationSharing({super.key});

  @override
  State<LocationSharing> createState() => _LocationSharingState();
}

class _LocationSharingState extends State<LocationSharing> {
  late CameraPosition _initialLocation;
  final Set<Marker> myMarker = {};
  GoogleMapController? _controller;
  final Completer<GoogleMapController> _mapsController = Completer();
  Polyline? route;
  bool isHaveLastSessionLocation = false;
  late StreamSubscription<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    setInitialLocation();
    trackLocation();
  }

  Future<void> setInitialLocation() async {
    Position position = await getCurrentLocation();
    _initialLocation = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 13,
    );
    myMarker.add(Marker(
      markerId: const MarkerId('myMarker'),
      position: LatLng(position.latitude, position.longitude),
    ));
    setState(() {}); // Gọi setState để cập nhật UI
  }

  void trackLocation() {
    final geolocator = GeolocatorPlatform.instance;
    _positionStream = geolocator.getPositionStream().listen(
          (Position position) async {
        final GoogleMapController controller = await _mapsController.future;
        final double currentZoomLevel = await controller.getZoomLevel(); // Lấy mức zoom hiện tại
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: currentZoomLevel, // Sử dụng mức zoom hiện tại
          ),
        ));
        setState(() {
          myMarker.clear();
          myMarker.add(Marker(
            markerId: const MarkerId('myMarker'),
            position: LatLng(position.latitude, position.longitude),
          ));
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _positionStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: <Widget>[
          GoogleMap(
            initialCameraPosition: _initialLocation!,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: myMarker.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _mapsController.complete(controller);
            },
            polylines: {if (route != null) route!},
            zoomControlsEnabled: false,
          ),
          FloatingActionButton(onPressed: () async {
            Position position = await getCurrentLocation();
            final GoogleMapController controller = await _mapsController.future;
            final double currentZoomLevel = await controller.getZoomLevel(); // Lấy mức zoom hiện tại
            controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: currentZoomLevel, // Sử dụng mức zoom hiện tại
              ),
            ));
          },
            child: const Icon(Icons.center_focus_strong),
          )]
        ));
  }
}