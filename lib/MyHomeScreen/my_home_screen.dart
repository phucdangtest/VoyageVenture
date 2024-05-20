import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/components/custom_search_field.dart';
import 'package:voyageventure/components/misc_widget.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/location_sharing.dart';
import 'package:voyageventure/main.dart';
import 'package:voyageventure/models/route_calculate_response.dart';
import 'package:voyageventure/utils.dart';
import 'package:voyageventure/features/current_location.dart';
import '../MyLocationSearch/my_location_search.dart';
import '../components/bottom_sheet_componient.dart';
import '../components/custom_search_delegate.dart';
import '../components/fonts.dart';
import '../components/location_list_tile.dart';
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
  late PlaceSearch_ markedPlace;
  bool placeFound = true;
  List<Marker> myMarker = [];
  BitmapDescriptor defaultMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor mainMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  Timer? _debounce;
  bool isShowPlaceHorizontalList = false; // show the location search component
  bool isShowPlaceHorizontalListFromSearch =
      true; // true: show from search, false: show from autocomplete

  //Route
  List<Route_> routes = [];
  Future<List<LatLng>?> polylinePoints = Future.value(null);
  Polyline? polyline;

  //Test

  static CameraPosition? _initialCameraPosition;
  static const LatLng _airPort = LatLng(10.8114795, 106.6548157);
  static const LatLng _dormitory = LatLng(10.8798036, 106.8052206);

  //State
  static const Map<String, int> stateMap = {
    "Default": 0,
    "Search Results": 1,
    "Route Planning": 2,
    "Navigation": 3,
    "Loading" : 10,
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
  void showPlaceHorizontalList(
      {required bool show, String nextState = "Default"}) {
      isShowPlaceHorizontalList = show;
      show == false
          ? changeState(nextState)
          : changeState("Search Results");
  }

  void changeState(String stateString) {
    if (!stateMap.containsKey(stateString)) {
      throw Exception('Invalid state: $stateString');
    }

    setState(() {
      state = stateMap[stateString]!;
    });
  }
  void searchPlaceAndUpdate(String text) {
    if (text.isEmpty) {
      placeFound = true;
      placeSearchList.clear();
      showPlaceHorizontalList(show: false);
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
              placeOnclick(isShowPlaceHorizontalListFromSearch: true, index: 0);

              animateBottomSheet(
                      _dragableController, defaultBottomSheetHeight / 1000)
                  .then((_) {
                setState(() {
                  bottomSheetTop = _dragableController.pixels;
                  showPlaceHorizontalList(show: true);
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
        showPlaceHorizontalList(show: false);
      });
    } else {
      logWithTag("Place auto complete: $text", tag: "SearchLocationScreen");
      setState(() {
        placeAutocomplete(text, currentLocation, 500)
            .then((autoList) => setState(() {
                  if (autoList != null) {
                    placeAutoList = autoList;
                    placeFound = true;
                    showPlaceHorizontalList(show: true);
                  } else {
                    placeFound = false;
                  }
                }));
      });
    }
  }

  void locationButtonOnclick() {
    if (currentLocation != null) {
      animateToPosition(currentLocation!);
    }
    getCurrentLocation().then((value) {
      if (currentLocation != LatLng(value.latitude, value.longitude)) {
        currentLocation = LatLng(value.latitude, value.longitude);
        animateToPosition(currentLocation!);
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

  Future<LatLng?> placeOnclick(
      {required bool isShowPlaceHorizontalListFromSearch,
      required int index}) async {
    this.isShowPlaceHorizontalListFromSearch =
        isShowPlaceHorizontalListFromSearch;
    showPlaceHorizontalList(show: true);
    if (isShowPlaceHorizontalListFromSearch) {
      try {
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

  Future<void> placeMarkAndRoute(
      {required bool isShowPlaceHorizontalListFromSearch,
      required int index}) async {
    this.isShowPlaceHorizontalListFromSearch =
        isShowPlaceHorizontalListFromSearch;
    showPlaceHorizontalList(show: true);
    if (isShowPlaceHorizontalListFromSearch) {
      try {
        markedPlace = placeSearchList[index];
        routes = (await computeRoutesReturnRoute_(
            from: currentLocation!,
            to: LatLng(placeSearchList[index].location.latitude,
                placeSearchList[index].location.longitude)))!;
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
      routes = (await computeRoutesReturnRoute_(
          from: currentLocation!,
          to: LatLng(value.location.latitude, value.location.longitude)))!;
      return;
    }
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
            polylines: {if (polyline != null) polyline!},
            zoomControlsEnabled: false,
          ),
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
                                  placeOnclick(
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
                                  if (routes.isNotEmpty) {
                                    setState(() {
                                      polyline = Polyline(
                                        polylineId: const PolylineId("route"),
                                        color: Colors.green,
                                        width: 8,
                                        points: routes[0]
                                            .legs[0]
                                            .polyline
                                            .decodedPolyline(),
                                      );
                                    });
                                  }
                                },
                                child: Container(
                                  //margin: EdgeInsets.only(
                                  // left: 10.0, top: 10.0, bottom: 10.0),
                                  padding: EdgeInsets.all(10.0),
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
          Positioned(
            //On top search bar
            top: 50,
            child: Visibility(
                visible: true, //state == stateMap["Route Planning"]!,
                child: Column(
                  children: [
                    Row(children: [
                      IconButton(
                          onPressed: () {
                            //Todo: coi có lỗi ko
                            // setState(() {
                            //   state = stateMap["Default"]!;
                              showPlaceHorizontalList(show: false);
                            //});
                          },
                          icon: const Icon(Icons.arrow_back)),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        width: MediaQuery.of(context).size.width - 120,
                        child: TextField(
                          controller: _searchFieldController,
                          focusNode: _searchFieldFocusNode,
                          onSubmitted: (text) {
                            searchPlaceAndUpdate(text);
                          },
                          onChanged: (text) {
                            if (text.isEmpty) {
                              placeFound = true;
                              placeAutoList.clear();
                              showPlaceHorizontalList(show: false);
                            }
                            if (_debounce?.isActive ?? false) {
                              _debounce?.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 50), () {
                              autocompletePlaceAndUpdate(text);
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none, // No bottom line
                            prefixIcon: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  SvgPicture.asset("assets/icons/search.svg"),
                            ),
                            suffixIcon: _searchFieldFocusNode.hasFocus
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      _searchFieldController.clear();
                                      setState(() {
                                        placeAutoList.clear();
                                        placeFound = true;
                                        showPlaceHorizontalList(show: false);
                                      });
                                    },
                                  )
                                : IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                        "assets/icons/nearby_search.svg")), // End icon
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 10.0),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: IconButton(
                            padding: EdgeInsets.all(2),
                            onPressed: () {},
                            icon: Image.asset(
                              "assets/profile.png",
                            )),
                      ),
                    ]),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: (placeAutoList.isNotEmpty &&
                              _searchFieldFocusNode.hasFocus)
                          ? Container(
                              //Autocomplete list
                              margin: EdgeInsets.only(top: 30.0),
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
                                      placeOnclick(
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
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              setState(() {
                bottomSheetTop = _dragableController.pixels;
              });
              return true;
            },
            child: state == stateMap["Default"]!
                ? DraggableScrollableSheet(
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
                    ? DraggableScrollableSheet(
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
                                      changeState("Route Planning");
                                    },
                                    child: const Text("Chỉ đường"),
                                  )
                                ]),
                              ),
                            ),
                          );
                        },
                      )
                    : (state == stateMap["Route Planning"]!)
                        ? DraggableScrollableSheet(
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
                                      FilledButton(
                                        onPressed: () {
                                          changeState("Navigation");
                                        },
                                        child: const Text("Bắt đầu"),
                                      )
                                    ]),
                                  ),
                                ),
                              );
                            },
                          )
                        : (state == stateMap["Navigation"]!)
                            ? DraggableScrollableSheet(
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
                                          FilledButton(
                                            onPressed: () {
                                             changeState("Default");
                                            },
                                            child: const Text("Kết thúc"),
                                          )
                                        ]),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : (state == stateMap["Loading"]!)
                                ? DraggableScrollableSheet(
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
                                              SizedBox(
                                                height: 100,
                                              ),
                                              CircularProgressIndicator(
                                                color: Colors.green,
                                              )
                                            ]),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}
