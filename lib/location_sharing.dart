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
import 'package:firebase_core/firebase_core.dart';

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

  List<LatLng> friendLocations = [
    LatLng(10.880247, 106.805416),
    LatLng(10.8672655, 106.8071607),
  ];

  FirebaseFirestore get firestore => FirebaseFirestore
      .instance; // Function to add a user to the Firestore database
  Future<void> addUser(String userId, String name, GeoPoint location) async {
    // Create a new document with the user ID
    final userRef = firestore.collection('users').doc(userId);

    // Add user data, including an empty "friends" array initially
    await userRef.set({
      'name': name,
      'location': location,
      'lastup': DateTime.now().toIso8601String(), // Update timestamp
      'friends': [], // Empty friends array
    });
  }

  Future<void> createUserProfile(
      String userId, String name, String email, GeoPoint location) async {
    // Get a reference to the document with the user ID
    final userRef = firestore.collection('users').doc(userId);

    // Add user data
    await userRef.set({
      'name': name,
      'email': email,
      'location': location, // Add location to user data
      'lastup': DateTime.now().toIso8601String(),
      'friends': [],
    });
  }

  Future<void> updateUserProfile(String userId, GeoPoint newLocation) async {
    // Get a reference to the document with the user ID
    final userRef = firestore.collection('users').doc(userId);

    // Get the current document
    final doc = await userRef.get();

    // Get the current location
    final GeoPoint currentLocation = doc.get('location');

    // Update user data
    await userRef.update({
      'lastLocation': currentLocation,
      'location': newLocation,
      'lastup': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addFriend(String userId, String friendId) async {
    // Get a reference to the user document
    final userRef = firestore.collection('users').doc(userId);
    final friendRef = firestore.collection('users').doc(friendId);

    // Perform a transaction to ensure data consistency
    await firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final friendDoc = await transaction.get(friendRef);

      final currentUserFriends = (userDoc.get('friends') as List)
          .map((item) => item.toString())
          .toList();
      final currentFriendFriends = (friendDoc.get('friends') as List)
          .map((item) => item.toString())
          .toList();

      // Check if friend is already present for user
      if (!currentUserFriends.contains(friendId)) {
        // Update the user document with the new friend added
        transaction.update(userRef, {
          'friends': FieldValue.arrayUnion([friendId]),
        });
      }

      // Check if user is already present for friend
      if (!currentFriendFriends.contains(userId)) {
        // Update the friend document with the new friend added
        transaction.update(friendRef, {
          'friends': FieldValue.arrayUnion([userId]),
        });
      }
    });
  }

// Function to retrieve a user's friends (consider implementing pagination for large friend lists)
  Future<void> getFriends(String userId1, String userId2) async {
    // Get a reference to the user documents
    final userRef1 = firestore.collection('users').doc(userId1);
    final userRef2 = firestore.collection('users').doc(userId2);

    // Get the current documents
    final doc1 = await userRef1.get();
    final doc2 = await userRef2.get();

    // Get the current locations
    final GeoPoint currentLocation1 = doc1.get('location');
    final GeoPoint currentLocation2 = doc2.get('location');

    // Update user data
    await userRef1.update({
      'fr_lastLocation': currentLocation1,
      'fr_location': currentLocation2,
      // Update location with the location of the other user
      'fr_lastup': DateTime.now().toIso8601String(),
    });

    await userRef2.update({
      'fr_lastLocation': currentLocation2,
      'fr_location': currentLocation1,
      // Update location with the location of the other user
      'fr_lastup': DateTime.now().toIso8601String(),
    });
  }

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
              String email = 'nhancanh02@gmail.com';
              String password = 'maihan1609';

              final UserCredential authResult =
                  await firebaseAuth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              if (authResult.user != null) {
                final User user = authResult.user!;

                // GeoPoint newLocation = GeoPoint(
                //     10.8737481, 106.7911169); // replace with your new location
                // await createUserProfile(user.uid, user.displayName ?? '',
                //     user.email ?? '', newLocation);
                GeoPoint newLocation = GeoPoint(10.8737481, 106.7611169);
                await updateUserProfile(user.uid, newLocation);

                final snackBar = SnackBar(
                  content: Text('Đăng nhập thành công!'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'Đóng',
                    onPressed: () {},
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            } catch (e) {
              print('Đăng nhập thất bại: $e');
            }
          },
          child: const Icon(Icons.login),
        ),
      ),
      Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: Visibility(
          visible: _showWhiteBox,
          child: Container(
            height: 120,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      child: Text('MAI HÂN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          )), // Bold and 18px font size
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 20.0),
                const Expanded(
                  child: Text(
                      '255 Biscayne Blvd Way, Miami, FL 33131, United States'),
                ),
              ],
            ),
          ),
        ),
      ),
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
      Positioned(
          bottom: 20.0,
          right: 20.0,
          child: FloatingActionButton(
            onPressed: () async {
              final userId1 = 'user1_id';
              final userId2 = 'user2_id';
              final name1 = 'John Doe';
              final name2 = 'Jane Smith';
              final location1 = GeoPoint(10.8740927, 106.8064434);
              final location2 = GeoPoint(10.8706025, 106.8028352);

              await addUser(userId1, name1, location1);
              await addUser(userId2, name2, location2);
              await addFriend('USVKhmyX0ihlnpIU9Uvr4vCJ6JL2', userId2);

              final friends =
                  await getFriends('USVKhmyX0ihlnpIU9Uvr4vCJ6JL2', userId2);

              setState(() {
                friendLocations.add(LatLng(location2.latitude, location2.longitude));
              });
            },
          ))
    ]));
  }
}
