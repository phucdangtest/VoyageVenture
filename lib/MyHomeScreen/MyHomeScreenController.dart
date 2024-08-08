import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../MyLocationSearch/my_location_search.dart';
import '../constants.dart';
import '../features/current_location.dart';
import '../models/map_data.dart';
import '../models/map_style.dart';
import '../models/place_autocomplete.dart';
import '../models/place_search.dart';
import '../models/route_calculate.dart';
import '../models/route_calculate_response.dart';
import '../utils.dart';

class MyHomeScreenController extends GetxController {
  final Completer<GoogleMapController> _mapsController = Completer();
  ScrollController _listviewScrollController = ScrollController();
  DraggableScrollableController _dragableController =
      DraggableScrollableController();
  double? bottomSheetTop;
  String textFieldTopText = "Tìm kiếm";
  String textFieldBottomText = "";

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
  BitmapDescriptor endLocationMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

  List<BitmapDescriptor> waypointMarkers = [
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    //A
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    //H
    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    //No letter
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
  bool isFullScreen = false;
  List<bool> isChange = [false, false, false, false, false, false];
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

  //Map style
  MapType _currentMapType = MapType.normal;
  final List<dynamic> _mapThemes = [
    {
      'name': 'Satellite',
      'style': MapStyle().standard,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=satellite&style=element:labels%7Cvisibility:off&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.neighborhood%7Cvisibility:off&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Hybrid',
      'style': MapStyle().standard,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=satellite&style=element:labels%7Cvisibility:on&style=feature:administrative.land_parcel%7Cvisibility:on&style=feature:administrative.neighborhood%7Cvisibility:off&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Standard',
      'style': MapStyle().standard,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:labels%7Cvisibility:off&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.neighborhood%7Cvisibility:off&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Sliver',
      'style': MapStyle().sliver,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0xf5f5f5&style=element:labels%7Cvisibility:off&style=element:labels.icon%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x616161&style=element:labels.text.stroke%7Ccolor:0xf5f5f5&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0xbdbdbd&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:poi%7Celement:geometry%7Ccolor:0xeeeeee&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:poi.park%7Celement:geometry%7Ccolor:0xe5e5e5&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:road%7Celement:geometry%7Ccolor:0xffffff&style=feature:road.arterial%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:road.highway%7Celement:geometry%7Ccolor:0xdadada&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:transit.line%7Celement:geometry%7Ccolor:0xe5e5e5&style=feature:transit.station%7Celement:geometry%7Ccolor:0xeeeeee&style=feature:water%7Celement:geometry%7Ccolor:0xc9c9c9&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Retro',
      'style': MapStyle().retro,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0xebe3cd&style=element:labels%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x523735&style=element:labels.text.stroke%7Ccolor:0xf5f1e6&style=feature:administrative%7Celement:geometry.stroke%7Ccolor:0xc9b2a6&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.land_parcel%7Celement:geometry.stroke%7Ccolor:0xdcd2be&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0xae9e90&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:landscape.natural%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:poi%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x93817c&style=feature:poi.park%7Celement:geometry.fill%7Ccolor:0xa5b076&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x447530&style=feature:road%7Celement:geometry%7Ccolor:0xf5f1e6&style=feature:road.arterial%7Celement:geometry%7Ccolor:0xfdfcf8&style=feature:road.highway%7Celement:geometry%7Ccolor:0xf8c967&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0xe9bc62&style=feature:road.highway.controlled_access%7Celement:geometry%7Ccolor:0xe98d58&style=feature:road.highway.controlled_access%7Celement:geometry.stroke%7Ccolor:0xdb8555&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x806b63&style=feature:transit.line%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:transit.line%7Celement:labels.text.fill%7Ccolor:0x8f7d77&style=feature:transit.line%7Celement:labels.text.stroke%7Ccolor:0xebe3cd&style=feature:transit.station%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:water%7Celement:geometry.fill%7Ccolor:0xb9d3c2&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x92998d&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Dark',
      'style': MapStyle().dark,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0x212121&style=element:labels%7Cvisibility:off&style=element:labels.icon%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x757575&style=element:labels.text.stroke%7Ccolor:0x212121&style=feature:administrative%7Celement:geometry%7Ccolor:0x757575&style=feature:administrative.country%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.locality%7Celement:labels.text.fill%7Ccolor:0xbdbdbd&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:poi.park%7Celement:geometry%7Ccolor:0x181818&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:poi.park%7Celement:labels.text.stroke%7Ccolor:0x1b1b1b&style=feature:road%7Celement:geometry.fill%7Ccolor:0x2c2c2c&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x8a8a8a&style=feature:road.arterial%7Celement:geometry%7Ccolor:0x373737&style=feature:road.highway%7Celement:geometry%7Ccolor:0x3c3c3c&style=feature:road.highway.controlled_access%7Celement:geometry%7Ccolor:0x4e4e4e&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:transit%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:water%7Celement:geometry%7Ccolor:0x000000&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x3d3d3d&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Night',
      'style': MapStyle().night,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0x242f3e&style=element:labels%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x746855&style=element:labels.text.stroke%7Ccolor:0x242f3e&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.locality%7Celement:labels.text.fill%7Ccolor:0xd59563&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0xd59563&style=feature:poi.park%7Celement:geometry%7Ccolor:0x263c3f&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x6b9a76&style=feature:road%7Celement:geometry%7Ccolor:0x38414e&style=feature:road%7Celement:geometry.stroke%7Ccolor:0x212a37&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x9ca5b3&style=feature:road.highway%7Celement:geometry%7Ccolor:0x746855&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0x1f2835&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0xf3d19c&style=feature:transit%7Celement:geometry%7Ccolor:0x2f3948&style=feature:transit.station%7Celement:labels.text.fill%7Ccolor:0xd59563&style=feature:water%7Celement:geometry%7Ccolor:0x17263c&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x515c6d&style=feature:water%7Celement:labels.text.stroke%7Ccolor:0x17263c&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    },
    {
      'name': 'Aubergine',
      'style': MapStyle().aubergine,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0x1d2c4d&style=element:labels%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x8ec3b9&style=element:labels.text.stroke%7Ccolor:0x1a3646&style=feature:administrative.country%7Celement:geometry.stroke%7Ccolor:0x4b6878&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0x64779e&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:administrative.province%7Celement:geometry.stroke%7Ccolor:0x4b6878&style=feature:landscape.man_made%7Celement:geometry.stroke%7Ccolor:0x334e87&style=feature:landscape.natural%7Celement:geometry%7Ccolor:0x023e58&style=feature:poi%7Celement:geometry%7Ccolor:0x283d6a&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x6f9ba5&style=feature:poi%7Celement:labels.text.stroke%7Ccolor:0x1d2c4d&style=feature:poi.park%7Celement:geometry.fill%7Ccolor:0x023e58&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x3C7680&style=feature:road%7Celement:geometry%7Ccolor:0x304a7d&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x98a5be&style=feature:road%7Celement:labels.text.stroke%7Ccolor:0x1d2c4d&style=feature:road.highway%7Celement:geometry%7Ccolor:0x2c6675&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0x255763&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0xb0d5ce&style=feature:road.highway%7Celement:labels.text.stroke%7Ccolor:0x023e58&style=feature:transit%7Celement:labels.text.fill%7Ccolor:0x98a5be&style=feature:transit%7Celement:labels.text.stroke%7Ccolor:0x1d2c4d&style=feature:transit.line%7Celement:geometry.fill%7Ccolor:0x283d6a&style=feature:transit.station%7Celement:geometry%7Ccolor:0x3a4762&style=feature:water%7Celement:geometry%7Ccolor:0x0e1626&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x4e6d70&size=164x132&key=${dotenv.env['MAPS_API_KEY1']}&scale=2'
    }
  ];

  //Search Field
  late TextEditingController _searchFieldControllerTop;
  late TextEditingController _searchFieldControllerBottom;
  late FocusNode _searchFieldFocusNodeTop;
  late FocusNode _searchFieldFocusNodeBottom;

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
          case 5:
            isFullScreen = !isFullScreen;
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
                    CheckboxListTile(
                      title: const Text('Hiện các điểm rẽ'),
                      value: isFullScreen,
                      onChanged: (bool? value) {
                        setState(() {
                          isFullScreen = value!;
                          isChange[5] = true;
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
                    if (isFullScreen) {
                      Navigator.of(context).pop();
                      changeState("Navigation");
                      return;
                    }

                    logWithTag(
                        "Options: $isTrafficAware, $isComputeAlternativeRoutes, $isAvoidTolls, $isAvoidHighways, $isAvoidFerries",
                        tag: "SearchLocationScreen");
                    calcRoute(
                        from: mapData.departureLocation!,
                        to: mapData.destinationLocationLatLgn!);
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

    if (stateString != "Navigation") {
      isFullScreen = false;
      deleteEndLocationsFromMarkers();
    } else
      addEndLocationsToMarkers();
    if (stateString == "Default") {
      isShowPlaceHorizontalList = false;
      polylines.clear();
      travelMode = "DRIVE";
      mapData.departureLocation = mapData.currentLocation;
      mapData.departureLocationName = "Vị trí hiện tại";
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

    state = stateMap[stateString]!;
    update();
  }

  void searchPlaceAndUpdate(String text) {
    if (text.isEmpty) {
      placeFound = true;
      placeSearchList.clear();
      update();
    } else {
      myMarker = [];
      logWithTag("Place search: $text", tag: "SearchLocationScreen");
      placeSearch(text).then((searchList) {
        if (searchList != null) {
          placeSearchList = searchList;
          for (int i = 0; i < placeSearchList.length; i++) {
            if (placeSearchList[i].id != null) {
              PlaceSearch_.getPhotoUrls(placeSearchList[i].id!, 500, 500)
                  .then((photoUrls) {
                placeSearchList[i].photoUrls = photoUrls;
                logWithTag("Photo URL: ${photoUrls}", tag: "Change photourl");
                update();
              });
            }
            final markerId = MarkerId(placeSearchList[i].id!);
            Marker marker = Marker(
              markerId: markerId,
              icon: (i == 0) ? mainMarker : defaultMarker,
              position: LatLng(placeSearchList[i].location.latitude,
                  placeSearchList[i].location.longitude),
            );
            myMarker.add(marker);
          }
          placeFound = true;
          placeOnclickFromList(
              isShowPlaceHorizontalListFromSearch: true, index: 0);

          animateBottomSheet(
                  _dragableController, defaultBottomSheetHeight / 1000)
              .then((_) {
            bottomSheetTop = _dragableController.pixels;
            changeState("Search Results");
            update();
          });
        } else {
          placeFound = false;
          update();
        }
      });
    }
  }

  void autocompletePlaceAndUpdate(String text) {
    if (text.isEmpty) {
      placeFound = true;
      placeAutoList.clear();
      update();
    } else {
      logWithTag("Place auto complete: $text", tag: "SearchLocationScreen");
      placeAutocomplete(text, mapData.currentLocation, 500).then((autoList) {
        if (autoList != null) {
          placeAutoList = autoList;
          placeFound = true;
          changeState("Search Results");
        } else {
          placeFound = false;
        }
        update();
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
    isShowPlaceHorizontalList = false;
    changeState("Loading Can Route");
    mapData.changeDestinationLocationLatLgn(position);
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
    update();

    try {
      String placeString = await convertLatLngToAddress(position);
      var value = await placeSearchSingle(placeString);
      if (value != null) {
        PlaceSearch_.getPhotoUrls(value.id!, 400, 400).then((photoUrls) {
          value.photoUrls = photoUrls;
            mapData.changeDestinationImage(photoUrls);
          update();
        });
        markedPlace = value;
        mapData.changeDestinationAddressAndPlaceNameAndImage(value);
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
        mapData.changeDestinationLocationLatLgn(LatLng(
            placeSearchList[index].location.latitude,
            placeSearchList[index].location.longitude));
        mapData.changeDestinationAddressAndPlaceNameAndImage(
            placeSearchList[index]);
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
      mapData.changeDestinationLocationLatLgn(
          LatLng(value.location.latitude, value.location.longitude));
      mapData.changeDestinationAddressAndPlaceNameAndImage(value);
      animateToPosition(
        LatLng(value.location.latitude, value.location.longitude),
      );
        myMarker = [];
        final markerId = MarkerId(value.id!);
        Marker marker = Marker(
          markerId: markerId,
          icon: mainMarker,
          position: LatLng(value.location.latitude, value.location.longitude),
          // infoWindow: InfoWindow(
          //   title: value.displayName?.text,
          //   snippet: value.formattedAddress,
          // ),
        );
        myMarker.add(marker);
      update();

      markedPlace = value;
      return LatLng(value.location.latitude, value.location.longitude);
    }
    return null;
  }

  void drawRoute() {
    if (routes.isNotEmpty) {
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
              color: polylineColors[i % polylineColors.length],
              // Use a different color for each leg
              width: width,
              // Use different widths for each polyline
              points: legPoints, // Add all points of the leg to the polyline
            ),
          );
        }
        update();

    }
    //showAllMarkerInfo();
  }

  // Future<void> showAllMarkerInfo() async {
  //   GoogleMapController controller = await _mapsController.future;
  //   for (final marker in myMarker) {
  //     controller.showMarkerInfoWindow(marker.markerId);
  //   }
  // }

  void clearRoute() {
      polylines.clear();
      update();

  }

  Future<void> calcRouteFromDepToDes() async {
    //Todo remove after test waypoint
    //waypointsLatLgn = [];
    if (mapData.departureLocation != null &&
        mapData.destinationLocationLatLgn != null) {
      List<Marker> tempList = List<Marker>.from(myMarker);

        for (Marker marker in tempList) {
          if (marker.icon == mainMarker) {
            myMarker.removeAt(tempList.indexOf(marker));
          }
        }

        Marker marker = Marker(
          markerId: MarkerId("0"),
          icon: mainMarker,
          position: mapData.destinationLocationLatLgn!,
        );
        myMarker.add(marker);
      update();

      calcRoute(
          from: mapData.departureLocation!,
          to: mapData.destinationLocationLatLgn!);
      _searchFieldControllerTop.text = mapData.departureLocationName;
      _searchFieldControllerBottom.text = mapData.destinationLocationPlaceName;
    }
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
    updateEndLocationAddress();
    drawRoute();
    changeState("Route Planning");
    mapData.changeDepartureLocation(from);
    mapData.changeDestinationLocationLatLgn(to);
    // Todo: mapdata
  }

  Future<void> updateEndLocationAddress() async {
    if (routes.isEmpty) return;
    if (routes[0].legs[0].steps == null) return;
    for (Step_ step in routes[0].legs[0].steps!) {
      if (step.endLocationAddress == null) {
        String placeString =
            await convertLatLngToAddress(step.endLocation.latLng);
        step.endLocationAddress = placeString;
      }
    }
  }

  void addEndLocationsToMarkers() {
    logWithTag("addEndLocationsToMarkers", tag: "MyHomeScreen");
      if (routes.isEmpty) return;
      for (Step_ step in routes[0].legs[0].steps!) {
        final markerId = MarkerId("End: ${step.endLocation.latLng}");
        Marker marker = Marker(
          markerId: markerId,
          icon: endLocationMarker,
          position: step.endLocation.latLng,
          infoWindow: InfoWindow(
            title: step.endLocationAddress,
          ),
        );
        myMarker.add(marker);
      }
    update();

  }

  void deleteEndLocationsFromMarkers() {
    for (int i = 0; i < myMarker.length; i++) {
      Marker marker = myMarker[i];
      if (marker.icon == endLocationMarker) {
        myMarker.removeAt(i);
      }
    }
  }

  Future<void> placeMarkAndRoute(
      {required bool isShowPlaceHorizontalListFromSearch,
      required int index}) async {
    changeState("Loading");
    this.isShowPlaceHorizontalListFromSearch =
        isShowPlaceHorizontalListFromSearch;
    myMarker.removeWhere((marker) => marker.icon != mainMarker);
    if (isShowPlaceHorizontalListFromSearch) {
      mapData.destinationLocationLatLgn = LatLng(
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
        myMarker = [];
        final markerId = MarkerId(value.id!);
        Marker marker = Marker(
          markerId: markerId,
          icon: mainMarker,
          position: LatLng(value.location.latitude, value.location.longitude),
          // infoWindow: InfoWindow(
          //   title: value.displayName?.text,
          //   snippet: value.formattedAddress,
          // ),
        );
        myMarker.add(marker);
        update();

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
          //infoWindow: marker.infoWindow,
        );
        myMarker[i] = newMarker;
      }
    }

    Marker markerAtIndex = myMarker[index];
    Marker newMarkerAtIndex = Marker(
      markerId: markerAtIndex.markerId,
      icon: mainMarker,
      position: markerAtIndex.position,
      //infoWindow: markerAtIndex.infoWindow,
    );
      myMarker[index] = newMarkerAtIndex;
    update();

  }

  @override
void onInit() {
  super.onInit();

  _searchFieldControllerBottom = TextEditingController();
  _searchFieldControllerTop = TextEditingController();
  _searchFieldFocusNodeTop = FocusNode();
  _searchFieldFocusNodeBottom = FocusNode();

  getCurrentLocationLatLng().then((value) {
    mapData.changeCurrentLocation(value);
    mapData.changeDepartureLocation(value);
    if (!isHaveLastSessionLocation) {
      animateToPosition(mapData.currentLocation!);
    }
  });

  animationController = AnimationController(
    duration: const Duration(seconds: 5),
    vsync: this,
  );

  moveAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.fastOutSlowIn,
  );

  BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
      "assets/icons/marker_small.svg", const Size(40, 40))
      .then((bitmapDescriptor) {
    defaultMarker = bitmapDescriptor;
    update();
  });

  BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
      "assets/icons/marker_big.svg", const Size(50, 50))
      .then((bitmapDescriptor) {
    mainMarker = bitmapDescriptor;
    update();
  });

  BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
      "assets/icons/end_location.svg", const Size(40, 40))
      .then((bitmapDescriptor) {
    endLocationMarker = bitmapDescriptor;
    update();
  });

  for (int i = 0; i < waypointMarkers.length; i++) {
    BitmapDescriptorHelper.getBitmapDescriptorFromSvgAsset(
        waypointMarkersSource[i], const Size(45, 45))
        .then((bitmapDescriptor) {
      waypointMarkers[i] = bitmapDescriptor;
      update();
    });
  }
}

@override
void onClose() {
  animationController.dispose();
  _searchFieldControllerTop.dispose();
  _searchFieldControllerBottom.dispose();
  _searchFieldFocusNodeTop.dispose();
  _searchFieldFocusNodeBottom.dispose();
  super.onClose();
}
}
