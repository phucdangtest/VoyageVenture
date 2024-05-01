import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/components/misc_widget.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/main.dart';
import 'package:voyageventure/utils.dart';
import 'package:voyageventure/features/current_location.dart';
import '../MyLocationSearch/my_location_search.dart';
import '../components/bottom_sheet_componient.dart';
import '../components/fonts.dart';
import '../components/location_list_tile.dart';
import '../models/place_autocomplete.dart';
import '../models/place_search.dart';

class MyHomeScreen extends StatefulWidget {
  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  //Controller
  final Completer<GoogleMapController> _mapsController = Completer();
  ScrollController _listviewScrollController = ScrollController();
  DraggableScrollableController _dragableController =
      DraggableScrollableController();
  double? bottomSheetTop;

  //Animation
  late AnimationController _animationController;
  late Animation<double> moveAnimation;

  //GeoLocation
  LatLng? currentLocation;
  bool isHaveLastSessionLocation = false;

  Future<LatLng> getCurrentLocationLatLng() async {
    Position position = await getCurrentLocation();
    return LatLng(position.latitude, position.longitude);
  }

  void animateToPosition(LatLng position, {double zoom = 13}) async {
    logWithTag("Animate to position: $position", tag: "MyHomeScreen");
    GoogleMapController controller = await _mapsController.future;
    CameraPosition cameraPosition = CameraPosition(
      target: position,
      zoom: zoom, // Change this value to your desired zoom level
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  //Location
  List<PlaceAutocomplete_> placeAutoList = [];
  List<PlaceSearch_> placeSearchList = [];
  bool placeFound = true;
  List<Marker> myMarker = [];
  BitmapDescriptor defaultMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor mainMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  //Route
  Future<List<LatLng>?> polylinePoints = Future.value(null);
  Polyline? route;

  //Test
  static CameraPosition? _initialCameraPosition;
  static const LatLng _airPort = LatLng(10.8114795, 106.6548157);
  static const LatLng _dormitory = LatLng(10.8798036, 106.8052206);

  @override
  void initState() {
    super.initState();

    getCurrentLocationLatLng().then((value) {
      currentLocation = value;
      if (!isHaveLastSessionLocation) {
        animateToPosition(currentLocation!);
      }
    });

    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    moveAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
            "assets/icons/marker_small.svg", const Size(40, 40))
        .then((bitmapDescriptor) {
      setState(() {
        defaultMarker = bitmapDescriptor;
      });
    });

    BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
            "assets/icons/marker_big.svg", const Size(50, 50))
        .then((bitmapDescriptor) {
      setState(() {
        mainMarker = bitmapDescriptor;
      });
    });

    WidgetsBinding.instance.addObserver(this);
    // _dragableController.addListener(() {
    //   setState(() {
    //     bottomSheetTop = _dragableController.pixels;
    //   });
    // });
  } // InitState

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger rebuild of the map
      setState(() {});
    }
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
          GoogleMap(
            initialCameraPosition: (isHaveLastSessionLocation ==
                    true) // get last location from shared preference, if not exist, use default location, then it will automatically move to current location
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
            markers: myMarker.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _mapsController.complete(controller);
            },
            polylines: {if (route != null) route!},
            zoomControlsEnabled: false,
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            bottom: (bottomSheetTop == null)
                ? (MediaQuery.of(context).size.height *
                        defaultBottomSheetHeight /
                        1000) +
                    10
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
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: defaultPadding,
                                          right: 0,
                                          top: defaultPadding,
                                          bottom: 8.0),
                                      child: CupertinoSearchTextField(
                                        style: leagueSpartanNormal20,
                                        placeholder: "Tìm địa điểm",
                                        onChanged: (text) {
                                          if (text.isEmpty) {
                                            setState(() {
                                              placeFound = true;
                                              placeAutoList.clear();
                                            });
                                          } else {
                                            logWithTag(
                                                "Place auto complete: $text",
                                                tag: "SearchLocationScreen");
                                            setState(() {
                                              placeAutocomplete(text,
                                                      currentLocation, 500)
                                                  .then((autoList) =>
                                                      setState(() {
                                                        if (autoList != null) {
                                                          placeAutoList =
                                                              autoList;
                                                          placeFound = true;
                                                        } else {
                                                          placeFound = false;
                                                        }
                                                      }));
                                            });
                                          }
                                        },
                                        onSubmitted: (text) {
                                          if (text.isEmpty) {
                                            placeFound = true;
                                            placeSearchList.clear();
                                          } else {
                                            setState(() {
                                              myMarker = [];
                                            });
                                            logWithTag("Place search: $text",
                                                tag: "SearchLocationScreen");
                                            placeSearch(text).then(
                                                (searchList) => setState(() {
                                                      if (searchList != null) {
                                                        placeSearchList =
                                                            searchList;
                                                        for (int i = 0;
                                                            i <
                                                                placeSearchList
                                                                    .length;
                                                            i++) {
                                                          final markerId =
                                                              MarkerId(
                                                                  placeSearchList[
                                                                          i]
                                                                      .id!);
                                                          final marker = Marker(
                                                            markerId: markerId,
                                                            icon: (i == 0)
                                                                ? mainMarker
                                                                : defaultMarker,
                                                            position: LatLng(
                                                                placeSearchList[
                                                                        i]
                                                                    .location
                                                                    .latitude,
                                                                placeSearchList[
                                                                        i]
                                                                    .location
                                                                    .longitude),
                                                            infoWindow:
                                                                InfoWindow(
                                                              title:
                                                                  placeSearchList[
                                                                          i]
                                                                      .displayName
                                                                      ?.text,
                                                              snippet:
                                                                  placeSearchList[
                                                                          i]
                                                                      .formattedAddress,
                                                            ),
                                                          );
                                                          myMarker.add(marker);
                                                        }
                                                        placeFound = true;

                                                        LatLng firstLocation =
                                                            LatLng(
                                                                placeSearchList[
                                                                        0]
                                                                    .location
                                                                    .latitude,
                                                                placeSearchList[
                                                                        0]
                                                                    .location
                                                                    .longitude);
                                                        animateToPosition(
                                                            firstLocation,
                                                            zoom: 15);

                                                        animateBottomSheet(
                                                                _dragableController,
                                                                defaultBottomSheetHeight /
                                                                    1000)
                                                            .then((_) {
                                                          setState(() {
                                                            bottomSheetTop =
                                                                _dragableController
                                                                    .pixels;
                                                          });
                                                        });
                                                      } else {
                                                        placeFound = false;
                                                      }
                                                    }));
                                          }
                                        },
                                        onTap: () async{
                                          logWithTag("Search bar clicked: ",
                                              tag: "SearchLocationScreen");

                                          await Future.delayed(const Duration(
                                                milliseconds: 500));
                                            animateBottomSheet(
                                                    _dragableController, 0.8)
                                                .then((_) {
                                              setState(() {
                                                bottomSheetTop =
                                                    _dragableController.pixels;
                                              });
                                            });

                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () {},
                                      icon: SvgPicture.asset(
                                          "assets/icons/nearby_search.svg")),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.only(
                                        left: defaultPadding, right: 8),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        logWithTag("Add home button clicked: ",
                                            tag: "SearchLocationScreen");
                                      },
                                      icon: SvgPicture.asset(
                                        "assets/icons/home_add.svg",
                                        height: 16,
                                      ),
                                      label: Text("Thêm nhà",
                                          style: leagueSpartanNormal15),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            secondaryColor10LightTheme,
                                        foregroundColor: textColorLightTheme,
                                        elevation: 0,
                                        fixedSize:
                                            const Size(double.infinity, 40),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      logWithTag("Button clicked: ",
                                          tag: "SearchLocationScreen");
                                    },
                                    icon: SvgPicture.asset(
                                      "assets/icons/location_add.svg",
                                      height: 16,
                                    ),
                                    label: Text("Thêm địa điểm",
                                        style: leagueSpartanNormal15),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          secondaryColor10LightTheme,
                                      foregroundColor: textColorLightTheme,
                                      elevation: 0,
                                      fixedSize:
                                          const Size(double.infinity, 40),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              placeFound
                                  ? ListView.builder(
                                      controller: _listviewScrollController,
                                      shrinkWrap: true,
                                      itemCount: placeAutoList.length,
                                      itemBuilder: (context, index) {
                                        return LocationListTile_(
                                          press: () {
                                            logWithTag(
                                                "Location clicked: ${placeAutoList[index].toString()}",
                                                tag: "SearchLocationScreen");
                                            SystemChannels.textInput
                                                .invokeMethod('TextInput.hide');
                                            animateBottomSheet(
                                                    _dragableController,
                                                    defaultBottomSheetHeight /
                                                        1000)
                                                .then((_) {
                                              setState(() {
                                                bottomSheetTop =
                                                    _dragableController.pixels;
                                              });
                                            });
                                            placeSearchSingle(
                                                    placeAutoList[index]
                                                            .structuredFormat
                                                            ?.mainText
                                                            ?.text ??
                                                        "")
                                                .then((value) => {
                                                      if (value != null)
                                                        {
                                                          animateToPosition(
                                                            LatLng(
                                                                value.location
                                                                    .latitude,
                                                                value.location
                                                                    .longitude),
                                                          ),
                                                          setState(() {
                                                            myMarker = [];
                                                            final markerId =
                                                                MarkerId(
                                                                    value.id!);
                                                            final marker =
                                                                Marker(
                                                              markerId:
                                                                  markerId,
                                                              icon: mainMarker,
                                                              position: LatLng(
                                                                  value.location
                                                                      .latitude,
                                                                  value.location
                                                                      .longitude),
                                                              infoWindow:
                                                                  InfoWindow(
                                                                title: value
                                                                    .displayName
                                                                    ?.text,
                                                                snippet: value
                                                                    .formattedAddress,
                                                              ),
                                                            );
                                                            myMarker
                                                                .add(marker);
                                                          }),
                                                        },
                                                    });
                                          },
                                          placeName: placeAutoList[index]
                                                  .structuredFormat
                                                  ?.mainText
                                                  ?.text ??
                                              "",
                                          location: placeAutoList[index]
                                                  .structuredFormat
                                                  ?.secondaryText
                                                  ?.text ??
                                              "",
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Text('Không tìm thấy địa điểm')),
                              //MockList_()
                            ],
                          ),
                          BottomSheetComponient_(
                              controller: _listviewScrollController),
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
