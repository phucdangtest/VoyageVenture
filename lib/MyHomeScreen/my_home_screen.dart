import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/components/custom_search_field.dart';
import 'package:voyageventure/components/route_planning_list_tile.dart';
import 'package:voyageventure/components/navigation_list_tile.dart';
import 'package:voyageventure/components/misc_widget.dart';
import 'package:voyageventure/components/waypoint_list.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/models/route_calculate_response.dart';
import 'package:voyageventure/utils.dart';
import 'package:voyageventure/features/current_location.dart';
import '../MyLocationSearch/my_location_search.dart';
import '../components/bottom_sheet_component.dart';
import '../components/custom_search_delegate.dart';
import '../components/fonts.dart';
import '../components/loading_indicator.dart';
import '../components/location_list_tile.dart';
import '../components/route_planning_list.dart';
import '../models/place_autocomplete.dart';
import '../models/place_search.dart';
import '../models/route_calculate.dart';

class MyHomeScreen extends StatefulWidget {
  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin {
  //Controller
  final Completer<GoogleMapController> _mapsController = Completer();
  ScrollController _listviewScrollController = ScrollController();
  DraggableScrollableController _dragableController =
      DraggableScrollableController();
  double? bottomSheetTop;

  //Animation
  late AnimationController _animationController;
  late Animation<double> moveAnimation;

  //double currentZoomLevel = 15;

  //GeoLocation
  MapData mapData = MapData();
  bool isHaveLastSessionLocation = false;
  LatLng centerLocation = LatLng(10.7981542, 106.6614047);

  void animateToPosition(LatLng position, {double zoom = 13}) async {
    logWithTag("Animate to position: $position", tag: "MyHomeScreen");
    GoogleMapController controller = await _mapsController.future;
    CameraPosition cameraPosition = CameraPosition(
      target: position,
      zoom: zoom, // Change this value to your desired zoom level
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  void animateToPositionNoZoom(LatLng position) async {
    logWithTag("Animate to position: $position", tag: "MyHomeScreen");
    GoogleMapController controller = await _mapsController.future;
    CameraPosition cameraPosition = CameraPosition(
      target: position,
      zoom: await controller.getZoomLevel(),
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  //Location
  List<PlaceAutocomplete_> placeAutoList = [];
  List<PlaceSearch_> placeSearchList = [];
  late PlaceSearch_ markedPlace;
  bool placeFound = true;
  List<Marker> myMarker = [];
  BitmapDescriptor defaultMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor mainMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  List<BitmapDescriptor> waypointMarkers = [
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), //A
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose), //H
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), //No letter
  ];

  List<String> waypointMarkersSource = [
   "assets/icons/waypoints/a.svg",
    "assets/icons/waypoints/b.svg",
    "assets/icons/waypoints/c.svg",
    "assets/icons/waypoints/d.svg",
    "assets/icons/waypoints/e.svg",
    "assets/icons/waypoints/f.svg",
    "assets/icons/waypoints/g.svg",
    "assets/icons/waypoints/h.svg",
    "assets/icons/marker_waypoint.svg",
  ];
  Timer? _debounce;
  bool isShowPlaceHorizontalList = false; // show the location search component
  bool isShowPlaceHorizontalListFromSearch =
      true; // true: show from search, false: show from autocomplete

  //Route
  List<Route_> routes = [];

  // Future<List<LatLng>?> polylinePoints = Future.value(null);
  List<Polyline> polylines = [];
  List<LatLng> polylinePointsList = [];
List<Color> polylineColors = [
  Colors.green[700]!,
  Colors.blue[700]!,
  Colors.yellow[700]!,
  Colors.purple[700]!,
  Colors.orange[700]!,
  Colors.brown[700]!,
  Colors.cyan[700]!,
  Colors.lime[700]!,
  Colors.teal[700]!,
  Colors.indigo[700]!,
];
  String travelMode = "DRIVE";
  String routingPreference = "TRAFFIC_AWARE";
  bool isTrafficAware = true;
  bool isComputeAlternativeRoutes = false;
  bool isAvoidTolls = false;
  bool isAvoidHighways = false;
  bool isAvoidFerries = false;
  List<bool> isChange = [false, false, false, false, false];
  bool isCalcRouteFromCurrentLocation = true;
  List<LatLng> waypointsLatLgn = [];
  List<String> waypointNames = [];

  //Test

  static CameraPosition? _initialCameraPosition;
  static const LatLng _airPort = LatLng(10.8114795, 106.6548157);
  static const LatLng _dormitory = LatLng(10.8798036, 106.8052206);

  //State
  static const Map<String, int> stateMap = {
    "Default": 0,
    "Search": 1,
    "Search Results": 2,
    "Route Planning": 3,
    "Navigation": 4,
    "Search Results None": 5,
    "Loading Can Route": 6,
    "Add Waypoint": 7,
    "Loading": 10,
  };
  int state = stateMap["Default"]!;

  String stateFromInt(int stateValue) {
    return stateMap.entries
        .firstWhere((entry) => entry.value == stateValue)
        .key;
  }

  //Search Field
  late TextEditingController _searchFieldController;
  late FocusNode _searchFieldFocusNode;

/*
 * This region contains functions.
 */
  // void showPlaceHorizontalList(
  //     {required bool show, String nextState = "Default"}) {
  //     isShowPlaceHorizontalList = show;
  //     show == false
  //         ? changeState(nextState)
  //         : changeState("Search Results");
  // }
  void updateOptionsBasedOnChanges() {
    for (int i = 0; i < isChange.length; i++) {
      if (isChange[i]) {
        switch (i) {
          case 0:
            isTrafficAware = !isTrafficAware;
            break;
          case 1:
            isComputeAlternativeRoutes = !isComputeAlternativeRoutes;
            break;
          case 2:
            isAvoidTolls = !isAvoidTolls;
            break;
          case 3:
            isAvoidHighways = !isAvoidHighways;
            break;
          case 4:
            isAvoidFerries = !isAvoidFerries;
            break;
        }
        // Reset the change flag for this option
        isChange[i] = false;
      }
    }
  }

  void showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tùy chọn đường đi'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    CheckboxListTile(
                      title: const Text('Ảnh hưởng giao thông'),
                      value: isTrafficAware,
                      onChanged: (bool? value) {
                        setState(() {
                          isTrafficAware = value!;
                          isChange[0] = true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Tính đường đi thay thế'),
                      value: isComputeAlternativeRoutes,
                      onChanged: (bool? value) {
                        setState(() {
                          isComputeAlternativeRoutes = value!;
                          isChange[1] = true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Tránh trạm thu phí'),
                      value: isAvoidTolls,
                      onChanged: (bool? value) {
                        setState(() {
                          isAvoidTolls = value!;
                          isChange[2] = true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Tránh đường cao tốc'),
                      value: isAvoidHighways,
                      onChanged: (bool? value) {
                        setState(() {
                          isAvoidHighways = value!;
                          isChange[3] = true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Tránh phà'),
                      value: isAvoidFerries,
                      onChanged: (bool? value) {
                        setState(() {
                          isAvoidFerries = value!;
                          isChange[4] = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy bỏ'),
                  onPressed: () {
                    setState(() {
                      updateOptionsBasedOnChanges();
                    });
                    logWithTag(
                        "Options: $isTrafficAware, $isComputeAlternativeRoutes, $isAvoidTolls, $isAvoidHighways, $isAvoidFerries",
                        tag: "SearchLocationScreen");
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Áp dụng'),
                  onPressed: () {
                    logWithTag(
                        "Options: $isTrafficAware, $isComputeAlternativeRoutes, $isAvoidTolls, $isAvoidHighways, $isAvoidFerries",
                        tag: "SearchLocationScreen");
                    calcRoute(
                        from: mapData.departureLocation!,
                        to: mapData.destinationLocation!);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void changeState(String stateString) {
    if (!stateMap.containsKey(stateString)) {
      throw Exception('Invalid state: $stateString');
    }

    if (stateString == "Search Results") {
      isShowPlaceHorizontalList = true;
      polylines.clear();
      travelMode = "TWO_WHEELER";
      //Todo remove after test waypoint
      //waypointsLatLgn = [];
    } else {
      isShowPlaceHorizontalList = false;
    }

    if (stateString == "Route Planning") {
      drawRoute();
    } else if (stateString == "Add Waypoint") {}

    setState(() {
      state = stateMap[stateString]!;
    });
  }

  void searchPlaceAndUpdate(String text) {
    if (text.isEmpty) {
      placeFound = true;
      placeSearchList.clear();
      setState(() {});
    } else {
      myMarker = [];
      logWithTag("Place search: $text", tag: "SearchLocationScreen");
      placeSearch(text).then((searchList) => setState(() {
            if (searchList != null) {
              placeSearchList = searchList;
              for (int i = 0; i < placeSearchList.length; i++) {
                final markerId = MarkerId(placeSearchList[i].id!);
                Marker marker = Marker(
                  markerId: markerId,
                  icon: (i == 0) ? mainMarker : defaultMarker,
                  position: LatLng(placeSearchList[i].location.latitude,
                      placeSearchList[i].location.longitude),
                  infoWindow: InfoWindow(
                    title: placeSearchList[i].displayName?.text,
                    snippet: placeSearchList[i].formattedAddress,
                  ),
                );
                myMarker.add(marker);
              }
              placeFound = true;
              placeOnclickFromList(
                  isShowPlaceHorizontalListFromSearch: true, index: 0);

              animateBottomSheet(
                      _dragableController, defaultBottomSheetHeight / 1000)
                  .then((_) {
                setState(() {
                  bottomSheetTop = _dragableController.pixels;
                  changeState("Search Results");
                });
              });
            } else {
              placeFound = false;
            }
          }));
    }
  }

  void autocompletePlaceAndUpdate(String text) {
    if (text.isEmpty) {
      setState(() {
        placeFound = true;
        placeAutoList.clear();
      });
    } else {
      logWithTag("Place auto complete: $text", tag: "SearchLocationScreen");
      setState(() {
        placeAutocomplete(text, mapData.currentLocation, 500)
            .then((autoList) => setState(() {
                  if (autoList != null) {
                    placeAutoList = autoList;
                    placeFound = true;
                    changeState("Search Results");
                  } else {
                    placeFound = false;
                  }
                }));
      });
    }
  }

  void locationButtonOnclick() {
    if (mapData.currentLocation != null) {
      animateToPosition(mapData.currentLocation!);
    }
    getCurrentLocation().then((value) {
      if (mapData.currentLocation != LatLng(value.latitude, value.longitude)) {
        mapData.currentLocation = LatLng(value.latitude, value.longitude);
        animateToPosition(mapData.currentLocation!);
        logWithTag("Location changed!", tag: "MyHomeScreen");
      }
    });
  }

  String getMainText(bool isShowFromSearch, int index) {
    if (isShowFromSearch) {
      return placeSearchList[index].displayName?.text ?? "";
    } else {
      return placeAutoList[index].structuredFormat?.mainText?.text ?? "";
    }
  }

  String getSecondaryText(bool isShowFromSearch, int index) {
    if (isShowFromSearch) {
      return placeSearchList[index].formattedAddress ?? "";
    } else {
      return placeAutoList[index].structuredFormat?.secondaryText?.text ?? "";
    }
  }

  Future<void> placeClickLatLngFromMap(LatLng position) async {
    animateToPositionNoZoom(
      LatLng(position.latitude, position.longitude),
    );
    changeState("Loading Can Route");
    mapData.changeDestinationLocation(position);
    setState(() {
      myMarker = [];
      waypointsLatLgn = [];
      waypointNames = [];
      final markerId = MarkerId("0");
      Marker marker = Marker(
        markerId: markerId,
        icon: mainMarker,
        position: LatLng(position.latitude, position.longitude),
      );
      myMarker.add(marker);
    });
    try {
      String placeString = await convertLatLngToAddress(position);
      var value = await placeSearchSingle(placeString);
      if (value != null) {
        markedPlace = value;
        if (state == stateMap["Loading Can Route"]!)
          changeState("Search Results");
      } else if (state == stateMap["Loading Can Route"]!)
        changeState("Search Results None");
    } catch (e) {
      logWithTag("Error, place click from map: $e",
          tag: "SearchLocationScreen");
    }
  }

  Future<LatLng?> placeOnclickFromList(
      {required bool isShowPlaceHorizontalListFromSearch,
      required int index}) async {
    this.isShowPlaceHorizontalListFromSearch =
        isShowPlaceHorizontalListFromSearch;
    changeState("Search Results");
    if (isShowPlaceHorizontalListFromSearch) {
      try {
        mapData.changeDestinationLocation(LatLng(
            placeSearchList[index].location.latitude,
            placeSearchList[index].location.longitude));
        animateToPosition(
            LatLng(placeSearchList[index].location.latitude,
                placeSearchList[index].location.longitude),
            zoom: 15);

        markedPlace = placeSearchList[index];
        return LatLng(placeSearchList[index].location.latitude,
            placeSearchList[index].location.longitude);
      } catch (e) {
        logWithTag(
            "Error, show from auto but the isShowFromSearch = true, changing it to false $e",
            tag: "SearchLocationScreen");
        isShowPlaceHorizontalListFromSearch = false;
      }
    }
    // If the isShowFromSearch is true, but the index is out of range, then it will change to false and execute this
    // Make sure that the isShowFromSearch is always have the right value

    var value = await placeSearchSingle(
        placeAutoList[index].structuredFormat?.mainText?.text ?? "");
    if (value != null) {
      mapData.changeDestinationLocation(
          LatLng(value.location.latitude, value.location.longitude));
      animateToPosition(
        LatLng(value.location.latitude, value.location.longitude),
      );
      setState(() {
        myMarker = [];
        final markerId = MarkerId(value.id!);
        Marker marker = Marker(
          markerId: markerId,
          icon: mainMarker,
          position: LatLng(value.location.latitude, value.location.longitude),
          infoWindow: InfoWindow(
            title: value.displayName?.text,
            snippet: value.formattedAddress,
          ),
        );
        myMarker.add(marker);
      });
      markedPlace = value;
      return LatLng(value.location.latitude, value.location.longitude);
    }
    return null;
  }

void drawRoute() {
  if (routes.isNotEmpty) {
    setState(() {
      polylines = [];
      for (int i = 0; i < routes[0].legs.length; i++) {
        List<LatLng> legPoints = Polyline_.decodePolyline(
            routes[0].legs[i].polyline.encodedPolyline);

        int width;
        switch (i % 3) {
          case 0:
            width = 8;
            break;
          case 1:
            width = 6;
            break;
          case 2:
            width = 4;
            break;
          default:
            width = 8;
        }

        polylines.add(
          Polyline(
            polylineId: PolylineId(i.toString()),
            color: polylineColors[i % polylineColors.length], // Use a different color for each leg
            width: width, // Use different widths for each polyline
            points: legPoints, // Add all points of the leg to the polyline
          ),
        );
      }
    });
  }
  showAllMarkerInfo();
}

  Future<void> showAllMarkerInfo() async {
    GoogleMapController controller = await _mapsController.future;
    for (final marker in myMarker) {
      controller.showMarkerInfoWindow(marker.markerId);
    }
  }

  void clearRoute() {
    setState(() {
      polylines.clear();
    });
  }

  Future<void> calcRouteFromDepToDes() async {
    //Todo remove after test waypoint
    //waypointsLatLgn = [];
    if (mapData.departureLocation != null &&
        mapData.destinationLocation != null)
      calcRoute(
          from: mapData.departureLocation!, to: mapData.destinationLocation!);
  }

  Future<void> calcRoute({required LatLng from, required LatLng to}) async {
    changeState("Loading");
    if (isTrafficAware) routingPreference = "TRAFFIC_AWARE";
    routes = (await computeRoutesReturnRoute_(
        from: from,
        to: to,
        travelMode: travelMode,
        routingPreference: routingPreference,
        computeAlternativeRoutes: isComputeAlternativeRoutes,
        avoidTolls: isAvoidTolls,
        avoidHighways: isAvoidHighways,
        avoidFerries: isAvoidFerries,
        waypoints: waypointsLatLgn))!;
    drawRoute();
    changeState("Route Planning");
    mapData.changeDepartureLocation(from);
    mapData.changeDestinationLocation(to);
  }

  Future<void> placeMarkAndRoute(
      {required bool isShowPlaceHorizontalListFromSearch,
      required int index}) async {
    changeState("Loading");
    this.isShowPlaceHorizontalListFromSearch =
        isShowPlaceHorizontalListFromSearch;
    myMarker.removeWhere((marker) => marker.icon != mainMarker);
    if (isShowPlaceHorizontalListFromSearch) {
      mapData.destinationLocation = LatLng(
          placeSearchList[index].location.latitude,
          placeSearchList[index].location.longitude);
      try {
        markedPlace = placeSearchList[index];
        calcRoute(
            from: mapData.currentLocation!,
            to: LatLng(placeSearchList[index].location.latitude,
                placeSearchList[index].location.longitude));
        return;
      } catch (e) {
        logWithTag(
            "Error, show from auto but the isShowFromSearch = true, changing it to false $e",
            tag: "SearchLocationScreen");
        isShowPlaceHorizontalListFromSearch = false;
      }
    }
    // If the isShowFromSearch is true, but the index is out of range, then it will change to false and execute this
    // Make sure that the isShowFromSearch is always have the right value
    var value = await placeSearchSingle(
        placeAutoList[index].structuredFormat?.mainText?.text ?? "");
    if (value != null) {
      setState(() {
        myMarker = [];
        final markerId = MarkerId(value.id!);
        Marker marker = Marker(
          markerId: markerId,
          icon: mainMarker,
          position: LatLng(value.location.latitude, value.location.longitude),
          infoWindow: InfoWindow(
            title: value.displayName?.text,
            snippet: value.formattedAddress,
          ),
        );
        myMarker.add(marker);
      });
      markedPlace = value;
      calcRoute(
          from: mapData.currentLocation!,
          to: LatLng(value.location.latitude, value.location.longitude));
      return;
    }
    logWithTag("Error, route not found", tag: "SearchLocationScreen");
    changeState("Search Results");
    return;
  }

  void changeMainMarker(int index) {
    for (int i = 0; i < myMarker.length; i++) {
      Marker marker = myMarker[i];
      if (marker.icon == mainMarker) {
        Marker newMarker = Marker(
          markerId: marker.markerId,
          icon: defaultMarker,
          position: marker.position,
          infoWindow: marker.infoWindow,
        );
        myMarker[i] = newMarker;
      }
    }

    Marker markerAtIndex = myMarker[index];
    Marker newMarkerAtIndex = Marker(
      markerId: markerAtIndex.markerId,
      icon: mainMarker,
      position: markerAtIndex.position,
      infoWindow: markerAtIndex.infoWindow,
    );
    setState(() {
      myMarker[index] = newMarkerAtIndex;
    });
  }

/*
 * End of functions
 */

  @override
  void initState() {
    super.initState();

    _searchFieldController = TextEditingController();
    _searchFieldFocusNode = FocusNode();

    getCurrentLocationLatLng().then((value) {
      mapData.changeCurrentLocation(value);
      mapData.changeDepartureLocation(value);
      if (!isHaveLastSessionLocation) {
        animateToPosition(mapData.currentLocation!);
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

    for (int i = 0; i < waypointMarkers.length; i++) {
      BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
          waypointMarkersSource[i], const Size(45, 45))
          .then((bitmapDescriptor) {
        setState(() {
          waypointMarkers[i] = bitmapDescriptor;
        });
      });
    }


    //Todo: Remove after test
    // searchPlaceAndUpdate("Đại học CNTT");
    // placeMarkAndRoute(isShowPlaceHorizontalListFromSearch: true, index: 0)
    //     .then((value) => {
    //           //changeState("Navigation")
    //         });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFieldController.dispose();
    _searchFieldFocusNode.dispose();
    super.dispose();
  }

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
    //return LocationSharing();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Maps
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
            onTap: (LatLng position) {
              placeClickLatLngFromMap(position);
            },
            onMapCreated: (GoogleMapController controller) {
              _mapsController.complete(controller);
            },
            onCameraMove: (CameraPosition position) {
              centerLocation = position.target;
            },
            polylines: polylines.toSet(),
            zoomControlsEnabled: false,
          ),

          // Horizontal list and location button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            bottom:
                isShowPlaceHorizontalList // use this to compensate the height of the location show panel when it showed,
                    // do not need to use this of use visibility widget, but that widget does not have animation
                    ? ((bottomSheetTop == null)
                        ? (MediaQuery.of(context).size.height *
                                defaultBottomSheetHeight /
                                1000) +
                            10
                        : bottomSheetTop! + 10)
                    : ((bottomSheetTop == null)
                        ? (MediaQuery.of(context).size.height *
                                defaultBottomSheetHeight /
                                1000) +
                            10 -
                            90 // 90 is the height of the location show panel
                        : bottomSheetTop! + 10 - 90),
            // 90 is the height of the location show panel

            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Location button
                Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  child: FloatingActionButton(
                    elevation: 5,
                    onPressed: () {
                      //setState(() {});
                      locationButtonOnclick();
                    },
                    //Map from state to statemap
                    child: Text(stateFromInt(state) ?? "Error"),
                    //const Icon(Icons.my_location_rounded),
                  ),
                ),

                // Location list
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: AnimatedOpacity(
                      opacity: isShowPlaceHorizontalList ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: SizedBox(
                        height: 90.0,
                        width: (MediaQuery.of(context).size.width),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: isShowPlaceHorizontalListFromSearch
                              ? placeSearchList.length
                              : placeAutoList.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin:
                                  const EdgeInsets.only(left: 5.0, right: 5),
                              child: GestureDetector(
                                onTap: () {
                                  placeOnclickFromList(
                                      isShowPlaceHorizontalListFromSearch:
                                          isShowPlaceHorizontalListFromSearch,
                                      index: index);
                                  if (myMarker.length > 1) {
                                    changeMainMarker(index);
                                  }
                                },
                                onLongPress: () async {
                                  await placeMarkAndRoute(
                                      isShowPlaceHorizontalListFromSearch:
                                          isShowPlaceHorizontalListFromSearch,
                                      index: index);
                                  drawRoute();
                                },
                                child: Container(
                                  //margin: EdgeInsets.only(
                                  // left: 10.0, top: 10.0, bottom: 10.0),
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Image.network(
                                        "https://lh5.googleusercontent.com/p/AF1QipNh59_JnDqMdtWpCIX9EJmG2Lqhcsfx2NJJjVyc=w408-h507-k-no",
                                        width: 50,
                                        height: 50,
                                      ),
                                      const SizedBox(width: 10.0),
                                      SizedBox(
                                        width: 140,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              getMainText(
                                                  isShowPlaceHorizontalListFromSearch,
                                                  index),
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              getSecondaryText(
                                                  isShowPlaceHorizontalListFromSearch,
                                                  index),
                                              style: const TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.grey,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                ),
              ],
            ),
          ),
          // Center image to add waypoint
          Visibility(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 27.0, right: 14.0),
                  child: SizedBox(
                      width: 35,
                      height: 35,
                      child: SvgPicture.asset("assets/icons/waypoint.svg")),
                ),
              ),
              visible: state == stateMap["Add Waypoint"]),

          // On top search bar
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                color: state == stateMap["Route Planning"]!
                    ? Colors.white
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Visibility(
                  //Top search bar - Departure
                  visible: state != stateMap["Add Waypoint"],
                  //state == stateMap["Search"]!,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 50.0,
                      ),
                      Column(
                        children: [
                          Row(children: [
                            IconButton(
                                onPressed: () {
                                  String currentState = stateFromInt(state);

                                  switch (currentState) {
                                    case "Search Results":
                                    case "Search Results None":
                                      changeState("Default");
                                      break;
                                    case "Route Planning":
                                    case "Loading Can Route":
                                      changeState("Search Results");
                                      break;
                                    case "Navigation":
                                      changeState("Route Planning");
                                      break;
                                    case "Loading":
                                      changeState("Search Results");
                                      break;
                                    default:
                                      changeState("Default");
                                      break;
                                  }
                                },
                                icon: const Icon(Icons.arrow_back)),
                            Container(
                              //Text input
                              margin: const EdgeInsets.only(left: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              width: MediaQuery.of(context).size.width - 120,
                              height: 45.0,
                              child: TextField(
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: SvgPicture.asset(
                                      "assets/icons/search.svg"),

                                  suffixIcon: _searchFieldFocusNode.hasFocus
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchFieldController.clear();
                                            setState(() {
                                              placeAutoList.clear();
                                              placeFound = true;
                                            });
                                          },
                                        )
                                      : IconButton(
                                          onPressed: () {},
                                          icon: SvgPicture.asset(
                                              "assets/icons/nearby_search.svg")), // End icon
                                ),
                                controller: _searchFieldController,
                                focusNode: _searchFieldFocusNode,
                                onSubmitted: (text) {
                                  searchPlaceAndUpdate(text);
                                  _searchFieldFocusNode.unfocus();
                                },
                                onChanged: (text) {
                                  if (text.isEmpty) {
                                    placeFound = true;
                                    placeAutoList.clear();
                                    setState(() {});
                                  }
                                  autocompletePlaceAndUpdate(text);
                                },
                              ),
                            ),
                            (state == stateMap["Default"]!)
                                ? Container(
                                    // Profile picture
                                    margin: const EdgeInsets.only(left: 10.0),
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: IconButton(
                                        padding: const EdgeInsets.all(2),
                                        onPressed: () {},
                                        icon: Image.asset(
                                          "assets/profile.png",
                                        )),
                                  )
                                : Container(
                                    // Profile picture
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        showOptionsDialog(context);
                                      },
                                    ),
                                  ),
                          ]),
                          Visibility(
                            //Bottom search bar - Destination
                            visible: state == stateMap["Route Planning"]!,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                120,
                                        height: 45,
                                        margin: const EdgeInsets.only(
                                            top: 10.0, right: 10.0, left: 65),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 5,
                                              blurRadius: 7,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            prefixIcon: SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: SvgPicture.asset(
                                                  "assets/icons/verified_destination.svg"),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: IconButton(
                                              onPressed: () {},
                                              icon: SvgPicture.asset(
                                                  "assets/icons/swap.svg"))),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              travelMode = "WALK";
                                              calcRouteFromDepToDes();
                                            },
                                            icon: SvgPicture.asset(
                                                "assets/icons/walk.svg")),
                                        const SizedBox(width: 10),
                                        IconButton(
                                            onPressed: () {
                                              travelMode = "DRIVE";
                                              calcRouteFromDepToDes();
                                            },
                                            icon: SvgPicture.asset(
                                                "assets/icons/car.svg")),
                                        const SizedBox(width: 10),
                                        IconButton(
                                            onPressed: () {
                                              travelMode = "TWO_WHEELER";
                                              calcRouteFromDepToDes();
                                            },
                                            icon: SvgPicture.asset(
                                                "assets/icons/motor.svg")),
                                        const SizedBox(width: 10),
                                        IconButton(
                                            onPressed: () {
                                              travelMode = "TRANSIT";
                                              calcRouteFromDepToDes();
                                            },
                                            icon: SvgPicture.asset(
                                                "assets/icons/public_transport.svg")),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: (placeAutoList.isNotEmpty &&
                                _searchFieldFocusNode.hasFocus)
                            ? Container(
                                //Autocomplete list
                                margin: const EdgeInsets.only(top: 30.0),
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width - 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: placeAutoList.length,
                                  itemBuilder: (context, index) {
                                    return LocationListTile_(
                                      press: () async {
                                        _searchFieldFocusNode.unfocus();
                                        logWithTag(
                                            "Location clicked: ${placeAutoList[index].toString()}",
                                            tag: "SearchLocationScreen");
                                        SystemChannels.textInput
                                            .invokeMethod('TextInput.hide');
                                        await Future.delayed(const Duration(
                                            milliseconds:
                                                500)); // wait for the keyboard to show up to make the bottom sheet move up smoothly
                                        animateBottomSheet(_dragableController,
                                                defaultBottomSheetHeight / 1000)
                                            .then((_) {
                                          setState(() {
                                            bottomSheetTop =
                                                _dragableController.pixels;
                                          });
                                        });
                                        placeOnclickFromList(
                                            isShowPlaceHorizontalListFromSearch:
                                                false,
                                            index: index);
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
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )),
            ),
          ),

          // Bottom sheet
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              setState(() {
                bottomSheetTop = _dragableController.pixels;
              });
              return true;
            },
            child: state == stateMap["Default"]!
                ?
                // Bottom sheet default
                DraggableScrollableSheet(
                    controller: _dragableController,
                    initialChildSize: defaultBottomSheetHeight / 1000,
                    minChildSize: 0.15,
                    maxChildSize: 1,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
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
                              // Column(
                              //   children: [
                              //     Row(
                              //       mainAxisAlignment:
                              //           MainAxisAlignment.center,
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.center,
                              //       children: [
                              //         Expanded(
                              //           child: Padding(
                              //             padding: const EdgeInsets.only(
                              //                 left: defaultPadding,
                              //                 right: 0,
                              //                 top: defaultPadding,
                              //                 bottom: 8.0),
                              //             child: CupertinoSearchTextField(
                              //               style: leagueSpartanNormal20,
                              //               placeholder: "Tìm địa điểm",
                              //               onChanged: (text) {
                              //                 if (_debounce?.isActive ??
                              //                     false) {
                              //                   _debounce?.cancel();
                              //                 }
                              //                 _debounce = Timer(
                              //                     const Duration(
                              //                         milliseconds: 200), () {
                              //                   autocompletePlaceAndUpdate(
                              //                       text);
                              //                 });
                              //               },
                              //               onSubmitted: (text) {
                              //                 searchPlaceAndUpdate(text);
                              //               },
                              //               onTap: () async {
                              //                 logWithTag(
                              //                     "Search bar clicked: ",
                              //                     tag:
                              //                         "SearchLocationScreen");
                              //                 isShowPlaceHorizontalList =
                              //                     false;
                              //                 await Future.delayed(const Duration(
                              //                     milliseconds:
                              //                         500)); // wait for the keyboard to show up to make the bottom sheet move up smoothly
                              //                 animateBottomSheet(
                              //                         _dragableController,
                              //                         0.8)
                              //                     .then((_) {
                              //                   setState(() {
                              //                     bottomSheetTop =
                              //                         _dragableController
                              //                             .pixels;
                              //                   });
                              //                 });
                              //               },
                              //             ),
                              //           ),
                              //         ),
                              //         IconButton(
                              //             onPressed: () {},
                              //             icon: SvgPicture.asset(
                              //                 "assets/icons/nearby_search.svg")),
                              //       ],
                              //     ),
                              //     Row(
                              //       children: <Widget>[
                              //         Container(
                              //           padding: const EdgeInsets.only(
                              //               left: defaultPadding, right: 8),
                              //           child: ElevatedButton.icon(
                              //             onPressed: () {
                              //               logWithTag(
                              //                   "Add home button clicked: ",
                              //                   tag: "SearchLocationScreen");
                              //             },
                              //             icon: SvgPicture.asset(
                              //               "assets/icons/home_add.svg",
                              //               height: 16,
                              //             ),
                              //             label: Text("Thêm nhà",
                              //                 style: leagueSpartanNormal15),
                              //             style: ElevatedButton.styleFrom(
                              //               backgroundColor:
                              //                   secondaryColor10LightTheme,
                              //               foregroundColor:
                              //                   textColorLightTheme,
                              //               elevation: 0,
                              //               fixedSize: const Size(
                              //                   double.infinity, 40),
                              //               shape:
                              //                   const RoundedRectangleBorder(
                              //                 borderRadius: BorderRadius.all(
                              //                     Radius.circular(20)),
                              //               ),
                              //             ),
                              //           ),
                              //         ),
                              //         ElevatedButton.icon(
                              //           onPressed: () {
                              //             logWithTag("Button clicked: ",
                              //                 tag: "SearchLocationScreen");
                              //           },
                              //           icon: SvgPicture.asset(
                              //             "assets/icons/location_add.svg",
                              //             height: 16,
                              //           ),
                              //           label: Text("Thêm địa điểm",
                              //               style: leagueSpartanNormal15),
                              //           style: ElevatedButton.styleFrom(
                              //             backgroundColor:
                              //                 secondaryColor10LightTheme,
                              //             foregroundColor:
                              //                 textColorLightTheme,
                              //             elevation: 0,
                              //             fixedSize:
                              //                 const Size(double.infinity, 40),
                              //             shape: const RoundedRectangleBorder(
                              //               borderRadius: BorderRadius.all(
                              //                   Radius.circular(20)),
                              //             ),
                              //           ),
                              //         ),
                              //       ],
                              //     ),
                              //
                              //     Visibility(
                              //       visible: placeFound,
                              //       child: ListView.builder(
                              //         controller: _listviewScrollController,
                              //         shrinkWrap: true,
                              //         itemCount: placeAutoList.length,
                              //         itemBuilder: (context, index) {
                              //           return LocationListTile_(
                              //             press: () async {
                              //               logWithTag(
                              //                   "Location clicked: ${placeAutoList[index].toString()}",
                              //                   tag: "SearchLocationScreen");
                              //
                              //               SystemChannels.textInput
                              //                   .invokeMethod(
                              //                       'TextInput.hide');
                              //               await Future.delayed(const Duration(
                              //                   milliseconds:
                              //                       500)); // wait for the keyboard to show up to make the bottom sheet move up smoothly
                              //               animateBottomSheet(
                              //                       _dragableController,
                              //                       defaultBottomSheetHeight /
                              //                           1000)
                              //                   .then((_) {
                              //                 setState(() {
                              //                   bottomSheetTop =
                              //                       _dragableController
                              //                           .pixels;
                              //                 });
                              //               });
                              //               placeOnclick(
                              //                   isShowPlaceHorizontalListFromSearch: false,
                              //                   index: index);
                              //             },
                              //             placeName: placeAutoList[index]
                              //                     .structuredFormat
                              //                     ?.mainText
                              //                     ?.text ??
                              //                 "",
                              //             location: placeAutoList[index]
                              //                     .structuredFormat
                              //                     ?.secondaryText
                              //                     ?.text ??
                              //                 "",
                              //           );
                              //         },
                              //       ),
                              //     ),
                              //     Visibility(
                              //       visible: !placeFound,
                              //       child: const Center(
                              //           child:
                              //               Text('Không tìm thấy địa điểm')),
                              //     ),
                              //     //MockList_()
                              //   ],
                              // ),
                              BottomSheetComponient_(
                                  controller: _listviewScrollController),
                            ]),
                          ),
                        ),
                      );
                    },
                  )
                : (state == stateMap["Search Results"]!)
                    ?
                    // Bottom sheet search results
                    DraggableScrollableSheet(
                        controller: _dragableController,
                        initialChildSize: defaultBottomSheetHeight / 1000,
                        minChildSize: 0.05,
                        maxChildSize: 1,
                        builder: (BuildContext context,
                            ScrollController scrollController) {
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
                                  FilledButton(
                                    onPressed: () {
                                      // placeMarkAndRoute(
                                      //     isShowPlaceHorizontalListFromSearch:
                                      //         isShowPlaceHorizontalListFromSearch,
                                      //     index: 0);
                                      calcRouteFromDepToDes();
                                    },
                                    child: const Text("Chỉ đường"),
                                  )
                                ]),
                              ),
                            ),
                          );
                        },
                      )
                    : (state == stateMap["Search Results None"]!)
                        ?
                        // Bottom sheet search results none
                        DraggableScrollableSheet(
                            controller: _dragableController,
                            initialChildSize: defaultBottomSheetHeight / 1000,
                            minChildSize: 0.05,
                            maxChildSize: 1,
                            builder: (BuildContext context,
                                ScrollController scrollController) {
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
                                        const Center(child: Text('Không tên')),
                                        FilledButton(
                                          onPressed: () {
                                            calcRoute(
                                                from:
                                                    mapData.departureLocation!,
                                                to: mapData
                                                    .destinationLocation!);
                                          },
                                          child: const Text("Chỉ đường"),
                                        ),
                                      ]),
                                    )),
                              );
                            },
                          )
                        : (state == stateMap["Route Planning"]!)
                            ?
                            // Bottom sheet route planning
                            DraggableScrollableSheet(
                                controller: _dragableController,
                                initialChildSize:
                                    defaultBottomSheetHeight / 1000,
                                minChildSize: 0.15,
                                maxChildSize: 1,
                                builder: (BuildContext context,
                                    ScrollController scrollController) {
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
                                          Container(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                changeState("Add Waypoint");
                                              },
                                              icon: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: SvgPicture.asset(
                                                      "assets/icons/add_waypoint.svg")),
                                              label: Text('Thêm điểm dừng'),
                                            ),
                                          ),
                                          RoutePlanningList(
                                              routes: routes,
                                              travelMode: travelMode,
                                              isAvoidTolls: isAvoidTolls,
                                              isAvoidHighways: isAvoidHighways,
                                              isAvoidFerries: isAvoidFerries,
                                              waypointsLatLgn: waypointsLatLgn,
                                              destinationLatLgn:
                                                  mapData.destinationLocation!,
                                              itemClick: (index) {
                                                //changeState("Navigation");
                                              })
                                        ]),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : (state == stateMap["Navigation"]!)
                                ?
                                // Bottom sheet navigation
                                DraggableScrollableSheet(
                                    controller: _dragableController,
                                    initialChildSize:
                                        defaultBottomSheetHeight / 1000,
                                    minChildSize: 0.15,
                                    maxChildSize: 1,
                                    builder: (BuildContext context,
                                        ScrollController scrollController) {
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
                                              // FilledButton(
                                              //   onPressed: () {
                                              //     changeState("Default");
                                              //   },
                                              //   child: const Text("Kết thúc"),
                                              // )
                                              Container(
                                                  child: ListView.builder(
                                                controller:
                                                    _listviewScrollController,
                                                shrinkWrap: true,
                                                itemCount: 2,
                                                itemBuilder: (context, index) {
                                                  return NavigationListTile();
                                                },
                                              ))
                                            ]),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : (state == stateMap["Loading Can Route"]!)
                                    ?
                                    // Bottom sheet loading can route
                                    DraggableScrollableSheet(
                                        controller: _dragableController,
                                        initialChildSize:
                                            defaultBottomSheetHeight / 1000,
                                        minChildSize: 0.15,
                                        maxChildSize: 1,
                                        builder: (BuildContext context,
                                            ScrollController scrollController) {
                                          return ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(24.0),
                                              topRight: Radius.circular(24.0),
                                            ),
                                            child: Container(
                                              color: Colors.white,
                                              child: SingleChildScrollView(
                                                primary: false,
                                                controller: scrollController,
                                                child:
                                                    Column(children: <Widget>[
                                                  const Pill(),
                                                  const SizedBox(
                                                    height: 30,
                                                  ),
                                                  Row(
                                                    children: [
                                                      const CircularProgressIndicator(
                                                        color: Colors.green,
                                                      ),
                                                      FilledButton(
                                                        onPressed: () {
                                                          calcRoute(
                                                              from: mapData
                                                                  .departureLocation!,
                                                              to: mapData
                                                                  .destinationLocation!);
                                                        },
                                                        child: const Text(
                                                            "Chỉ đường"),
                                                      ),
                                                    ],
                                                  )
                                                ]),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : (state == stateMap["Add Waypoint"]!)
                                        ?
                                        // Bottom sheet add waypoint
                                        DraggableScrollableSheet(
                                            controller: _dragableController,
                                            initialChildSize:
                                                defaultBottomSheetHeight / 1000,
                                            minChildSize: 0.15,
                                            maxChildSize: 1,
                                            builder: (BuildContext context,
                                                ScrollController
                                                    scrollController) {
                                              return ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(24.0),
                                                  topRight:
                                                      Radius.circular(24.0),
                                                ),
                                                child: Container(
                                                  color: Colors.white,
                                                  child: SingleChildScrollView(
                                                      primary: false,
                                                      controller:
                                                          scrollController,
                                                      child: Column(
                                                          children: <Widget>[
                                                            const Pill(),
                                                            Column(
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    SizedBox(
                                                                      width: 80,
                                                                      height:
                                                                          40,
                                                                      child: IconButton(
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              waypointsLatLgn.removeLast();
                                                                              waypointNames.removeLast();
                                                                              myMarker.removeLast();
                                                                            });
                                                                          },
                                                                          icon: SvgPicture.asset("assets/icons/remove.svg")),
                                                                    ),
                                                                    ElevatedButton(
                                                                        onPressed:
                                                                            () {
                                                                          calcRouteFromDepToDes();
                                                                        },
                                                                        child: Text(
                                                                            "Áp dụng")),
                                                                    SizedBox(
                                                                        width:
                                                                            80,
                                                                        height:
                                                                            40,
                                                                        child: IconButton(
                                                                            onPressed: () {
                                                                              setState(() {
                                                                                waypointsLatLgn.add(centerLocation);
                                                                                convertLatLngToAddress(centerLocation, isCutoff: true).then((value) {
                                                                                  setState(() {
                                                                                    waypointNames.add(value);
                                                                                  });
                                                                                });
                                                                                myMarker.add(Marker(
                                                                                  markerId: MarkerId(centerLocation.toString()),
                                                                                  icon: (myMarker.length < waypointMarkers.length)?
                                                                                  waypointMarkers[(myMarker.length - 1)]:
                                                                                  waypointMarkers[waypointMarkers.length - 1],
                                                                                  position: centerLocation,
                                                                                ));
                                                                              });
                                                                            },
                                                                            icon: SvgPicture.asset("assets/icons/add.svg")))
                                                                  ],
                                                                ),
                                                                TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        waypointsLatLgn
                                                                            .clear();
                                                                        myMarker.removeWhere((marker) =>
                                                                            marker.icon !=
                                                                            mainMarker);
                                                                      });
                                                                    },
                                                                    child: Text(
                                                                        "Xóa tất cả")),
                                                                WaypointList(
                                                                  waypoints:
                                                                      waypointsLatLgn,
                                                                  waypointsName:
                                                                      waypointNames,
                                                                ),
                                                              ],
                                                            ),
                                                          ])),
                                                ),
                                              );
                                            },
                                          )
                                        : (state == stateMap["Loading"]!)
                                            ?
                                            // Bottom sheet loading
                                            DraggableScrollableSheet(
                                                controller: _dragableController,
                                                initialChildSize:
                                                    defaultBottomSheetHeight /
                                                        1000,
                                                minChildSize: 0.15,
                                                maxChildSize: 1,
                                                builder: (BuildContext context,
                                                    ScrollController
                                                        scrollController) {
                                                  return ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(24.0),
                                                      topRight:
                                                          Radius.circular(24.0),
                                                    ),
                                                    child: Container(
                                                      color: Colors.white,
                                                      child:
                                                          SingleChildScrollView(
                                                        primary: false,
                                                        controller:
                                                            scrollController,
                                                        child: Column(
                                                            children: <Widget>[
                                                              const Pill(),
                                                              // SizedBox(
                                                              //   height: 100,
                                                              // ),
                                                              LoadingIndicator(
                                                                color: Colors
                                                                    .green,
                                                                onPressed: () {
                                                                  changeState(
                                                                      "Search Results");
                                                                },
                                                              ),
                                                            ]),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            :

                                            // Bottom sheet none
                                            const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}

class MapData {
  LatLng? currentLocation;
  LatLng? departureLocation;
  String departureLocationName;
  LatLng? destinationLocation;
  String? destinationLocationName;

  MapData({
    this.currentLocation,
    this.departureLocation,
    this.destinationLocation,
    this.departureLocationName = "Vị trí của bạn",
    this.destinationLocationName,
  });

  void changeDestinationLocation(LatLng latLng) {
    destinationLocation = latLng;
    logWithTag("Destination location changed to: $latLng", tag: "MapData");
    logWithTag(
        "All data: $currentLocation, $departureLocation, $destinationLocation",
        tag: "MapData");
    // Future<String?> placeString = convertLatLngToAddress(latLng);
    // placeString.then((value) {
    //   destinationLocationName = value ?? "Không có chi tiết";
    //   logWithTag("Destination location changed to: $value + $latLng",
    //       tag: "MapData");
    // });
  }

  void changeDepartureLocation(LatLng from) {
    departureLocation = from;
    logWithTag("Departure location changed to: $from", tag: "MapData");
    logWithTag(
        "All data: $currentLocation, $departureLocation, $destinationLocation",
        tag: "MapData");

    // Future<String?> placeString = convertLatLngToAddress(from);
    // placeString.then((value) {
    //   departureLocationName = value ?? "Không có chi tiết";
    //   logWithTag("Departure location changed to: $value + $from",
    //       tag: "MapData");
    // });
  }

  void changeCurrentLocation(LatLng value) {
    currentLocation = value;
    logWithTag("Current location changed to: $value", tag: "MapData");
    logWithTag(
        "All data: $currentLocation, $departureLocation, $destinationLocation",
        tag: "MapData");
  }
}
