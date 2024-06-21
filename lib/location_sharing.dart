import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math'; // Import math library for acos function
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:voyageventure/features/current_location.dart';
import 'package:voyageventure/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationSharing extends StatefulWidget {
  const LocationSharing({super.key});

  @override
  State<LocationSharing> createState() => _LocationSharingState();
}

bool distanceBetween(LatLng position1, LatLng position2) {
  double one = position1.latitude - position2.latitude;
  one = one.abs();
  double two = position1.longitude - position2.longitude;
  two = two.abs();
  if (one <= 0.0003 && two <= 0.0002) {
    return true;
  }
  return false;
}

class _LocationSharingState extends State<LocationSharing> {
  CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(0.0, 0.0));
  final Set<Marker> myMarker = {};
  GoogleMapController? _controller;
  bool _showWhiteBox = false; // State variable to control box visibility
  LatLng? _selectedLocation;
  final Completer<GoogleMapController> _mapsController = Completer();
  Polyline? route;
  bool isHaveLastSessionLocation = false;
  late StreamSubscription<Position> _positionStream;

  // Array to store latitude and longitude values
  final List<LatLng> friendLocations = [
    LatLng(10.880247, 106.805416),
    // Example location 1 (replace with actual values)
    LatLng(10.8672655, 106.8071607),
    // Example location 2 (replace with actual values)
  ];

  @override
  void initState() {
    super.initState();
    setInitialLocation();
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    firestore.collection('user').get().then((QuerySnapshot querySnapshot) {
      logWithTag("Get data from firestore", tag: "LocationSharing");
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
      String Email = documentSnapshot.get('Email');
      logWithTag("Data: ${Email}", tag: "LocationSharing");
    });

    //addFriendMarkers(); // Add markers for friend locations
    //trackLocation();
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
    setState(() {}); // Update UI
  }

  // void addFriendMarkers() {
  //   for (final location in friendLocations) {
  //     myMarker.add(Marker(
  //       markerId: MarkerId('friend_${friendLocations.indexOf(location)}'),
  //       // Unique ID for each friend marker
  //       position: location,
  //     ));
  //   }
  // }

  void trackLocation() {
    final geolocator = GeolocatorPlatform.instance;
    _positionStream = geolocator.getPositionStream().listen(
      (Position position) async {
        final GoogleMapController controller = await _mapsController.future;
        final double currentZoomLevel =
            await controller.getZoomLevel(); // Get current zoom level
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: currentZoomLevel,
          ),
        ));
        setState(() {
          myMarker.clear();
          // addFriendMarkers(); // Re-add friend markers after clearing
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

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  //final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: <Widget>[
      GoogleMap(
        initialCameraPosition: _initialLocation,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: myMarker.toSet(),
        onMapCreated: (GoogleMapController controller) {
          _mapsController.complete(controller);
        },
        onTap: (LatLng position) {
          for (final friendLocation in friendLocations) {
            if (distanceBetween(position, friendLocation)) {
              setState(() {
                _showWhiteBox = !_showWhiteBox; // Toggle _showWhiteBox
                if (_showWhiteBox) {
                  _selectedLocation = position; // Store tapped location
                }
              });
            }
          }
        },
        polylines: {if (route != null) route!},
        zoomControlsEnabled: false,
      ),
      Positioned(
        top: 20.0,
        right: 20.0,
        child: FloatingActionButton(
          onPressed: () async {
            try {
              // Trigger Google Sign-In
              final GoogleSignInAccount? googleUser =
                  await googleSignIn.signIn();

              if (googleUser != null) {
                // Retrieve Google authentication credentials
                final GoogleSignInAuthentication googleAuth =
                    await googleUser.authentication;

                // Create a Firebase credential object
                final credential = GoogleAuthProvider.credential(
                  accessToken: googleAuth.accessToken,
                  idToken: googleAuth.idToken,
                );

                // Sign in to Firebase with the credential
                final UserCredential authResult =
                    await firebaseAuth.signInWithCredential(credential);

                // Check for successful login
                if (authResult.user != null) {
                  final User user =
                      authResult.user!; // Access the logged-in user

                  // Show successful login SnackBar
                  final snackBar = SnackBar(
                    content: Text('Đăng nhập thành công!'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Đóng',
                      onPressed: () {},
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  // Get current location
                  Position position = await getCurrentLocation();

                  // Create a reference to the user's location node in Firestore
                  // final databaseReference = firestore
                  //     .collection('users')
                  //     .doc('${user.uid}')
                  //     .collection('location');

                  // Save location data as a map
                  final locationData = {
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  };


                  // Write location data to Firestore
                  // await databaseReference
                  //     .doc()
                  //     .set(locationData); // Use doc() for Firestore
                  print('Vị trí người dùng đã được lưu trên Firestore');
                } else {
                  print('Đăng nhập thất bại');
                  // Handle login failure (optional)
                }
              }
            } catch (e) {
              print(e);
            }
          },
          child: const Icon(Icons.login),
        ),
      ),
      Positioned(
        bottom: 20,
        left: 20, // Position at the left
        right: 20, // Position at the right
        child: Visibility(
          visible: _showWhiteBox, // Show only when _showWhiteBox is true
          child: Container(
            height: 120,
            // Adjust the height as needed
            width: MediaQuery.of(context).size.width,
            // Full width
            padding: const EdgeInsets.all(16.0),
            // Add padding
            decoration: BoxDecoration(
              color: Colors.white, // Set background color
              borderRadius: BorderRadius.circular(10.0), // Add rounded corners
            ),
            child: Column(
              // Use Column for vertical arrangement
              children: [
                Row(
                  // Row for "MAI HÂN" and Spacer
                  children: [
                    Container(
                      // Wrap "MAI HÂN" with a width
                      // width: 100.0, // Adjust width as needed
                      child: Text('MAI HÂN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          )), // Bold and 18px font size
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 20.0), // Add vertical space below name
                const Expanded(
                  // Fills remaining vertical space
                  child: Text(
                      '255 Biscayne Blvd Way, Miami, FL 33131, United States'),
                ),
              ],
            ),
          ),
        ),
      ),
      // Your existing FloatingActionButton
      FloatingActionButton(
        onPressed: () async {
          Position position = await getCurrentLocation();
          final GoogleMapController controller = await _mapsController.future;
          final double currentZoomLevel = await controller.getZoomLevel();
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: currentZoomLevel,
            ),
          ));
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    ]));
  }
}
