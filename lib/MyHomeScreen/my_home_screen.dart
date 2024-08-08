import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voyageventure/components/custom_search_field.dart';
import 'package:voyageventure/components/route_planning_list_tile.dart';
import 'package:voyageventure/components/navigation_list_tile.dart';
import 'package:voyageventure/components/misc_widget.dart';
import 'package:voyageventure/components/waypoint_list.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/models/fetch_photo_url.dart';
import 'package:voyageventure/models/route_calculate_response.dart';
import 'package:voyageventure/utils.dart';
import 'package:voyageventure/features/current_location.dart';
import '../MyLocationSearch/my_location_search.dart';
import '../components/bottom_sheet_component.dart';
import '../components/custom_search_delegate.dart';
import '../components/end_location_list.dart';
import '../components/fonts.dart';
import '../components/loading_indicator.dart';
import '../components/location_list_tile.dart';
import '../components/route_planning_list.dart';
import '../location_sharing.dart';
import '../models/map_data.dart';
import '../models/map_style.dart';
import '../models/place_autocomplete.dart';
import '../models/place_search.dart';
import '../models/route_calculate.dart';
import 'MyHomeScreenController.dart';
import 'package:get/get.dart';


class MyHomeScreen extends StatefulWidget {
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin {
  //Controller


/*
 * End of functions
 */
@override
void initState() {
  super.initState();
  Get.put(MyHomeScreenController());
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
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: myMarker.toSet(),
            onTap: (LatLng position) {
              if (state != stateMap["Route Planning"])
                placeClickLatLngFromMap(position);
            },
            onLongPress: (LatLng position) {
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
            // use this to compensate the height of the location show panel when it showed,
            // do not need to use this of use visibility widget, but that widget does not have animation
            ((bottomSheetTop == null)
                ? (MediaQuery.of(context).size.height *
                defaultBottomSheetHeight /
                1000) +
                10
                : bottomSheetTop! + 10),
            // 90 is the height of the location show panel

            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  child: FloatingActionButton(
                    elevation: 5,
                    backgroundColor: Colors.white,
                    heroTag: "mapStyle",
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                            padding: EdgeInsets.all(20),
                            color: Colors.white,
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Chọn chủ đề",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 100,
                                  child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _mapThemes.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () async {
                                            GoogleMapController controller = await _mapsController.future;
                                            if (index == 0) {
                                              _currentMapType = MapType.satellite;
                                            } else if (index == 1) {
                                              _currentMapType = MapType.hybrid;
                                            }
                                            else
                                              _currentMapType = MapType.normal;

                                            controller.setMapStyle(
                                                _mapThemes[index]['style']);
                                            setState(() {
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                              width: 100,
                                              margin: EdgeInsets.only(right: 10),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                  image: DecorationImage(
                                                    fit: BoxFit.cover,
                                                    image: NetworkImage(
                                                        _mapThemes[index]['image']),
                                                  )),
                                              child: Center(
                                                child: Stack(
                                                  children: [


                                                    Text(
                                                      _mapThemes[index]['name'],
                                                      style: TextStyle(
                                                          foreground: Paint()
                                                            ..style = PaintingStyle.stroke
                                                            ..strokeWidth = 2
                                                            ..color = Colors.white,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      _mapThemes[index]['name'],
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 18),
                                                    ),

                                                  ],
                                                ),
                                              )
                                          ),
                                        );
                                      }),
                                ),
                              ],
                            )),
                      );
                    },
                    child: Icon(Icons.layers_rounded, size: 25),
                  ),
                ),

                SizedBox(height: 10),
                // Location button
                Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  child: FloatingActionButton(
                    heroTag: "Location",
                    backgroundColor: Colors.white,
                    elevation: 5,
                    onPressed: () {
                      //setState(() {});
                      //addEndLocationsToMarkers();
                      locationButtonOnclick();
                    },
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Location list
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child:
                  //List from place autocomplete
                  Visibility(
                      visible: isShowPlaceHorizontalList,
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
                              margin: const EdgeInsets.only(
                                  left: 5.0, right: 5),
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
                                    borderRadius:
                                    BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.start,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: <Widget>[
                                      if (isShowPlaceHorizontalListFromSearch)
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(5.0),
                                          child: (placeSearchList[index]
                                              .photoUrls !=
                                              null)
                                              ? Image.network(
                                            placeSearchList[index]
                                                .photoUrls!,
                                            width: 60,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          )
                                              : SvgPicture.asset(
                                            "assets/icons/marker_big.svg",
                                            width: 60,
                                            height: 80,
                                            fit: BoxFit.scaleDown,
                                          ),
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
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              getSecondaryText(
                                                  isShowPlaceHorizontalListFromSearch,
                                                  index),
                                              style: const TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.grey,
                                                  overflow: TextOverflow
                                                      .ellipsis),
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

                                  suffixIcon: _searchFieldFocusNodeTop.hasFocus
                                      ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchFieldControllerTop.clear();
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
                                controller: _searchFieldControllerTop,
                                focusNode: _searchFieldFocusNodeTop,
                                onSubmitted: (text) {
                                  if (state == stateMap["Route Planning"]!) {
                                    changeState("Loading");
                                    placeSearch(text).then((value) {
                                      if (value != null) {
                                        mapData.changeDepartureLocation(LatLng(
                                            value[0].location.latitude,
                                            value[0].location.longitude));
                                        calcRouteFromDepToDes();
                                        _searchFieldControllerTop.text =
                                            value[0].displayName?.text ?? "";
                                      }
                                    });
                                  } else
                                    searchPlaceAndUpdate(text);
                                  _searchFieldFocusNodeTop.unfocus();
                                },
                                onChanged: (text) {
                                  if (state == stateMap["Route Planning"]!)
                                    return;

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
                                          controller:
                                          _searchFieldControllerBottom,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            prefixIcon: SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: SvgPicture.asset(
                                                  "assets/icons/verified_destination.svg"),
                                            ),
                                          ),
                                          onSubmitted: (text) {
                                            changeState("Loading");
                                            placeSearch(text).then((value) {
                                              if (value != null) {
                                                mapData
                                                    .changeDestinationLocationLatLgn(
                                                    LatLng(
                                                        value[0]
                                                            .location
                                                            .latitude,
                                                        value[0]
                                                            .location
                                                            .longitude));
                                                calcRouteFromDepToDes();
                                                _searchFieldControllerBottom
                                                    .text = value[0]
                                                    .displayName
                                                    ?.text ??
                                                    "";
                                              }
                                            });
                                            _searchFieldFocusNodeBottom
                                                .unfocus();
                                          },
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
                            _searchFieldFocusNodeTop.hasFocus)
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
                                  _searchFieldFocusNodeTop.unfocus();
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
                          controller: _listviewScrollController,
                          shareLocationPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      LocationSharing()),
                            );
                          },
                        ),
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
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20.0),
                        child: Column(children: <Widget>[
                          const Pill(),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(5.0),
                                child:
                                (mapData.destinationLocationPhotoUrl !=
                                    "")
                                    ? Image.network(
                                  mapData
                                      .destinationLocationPhotoUrl!,
                                  width: 80,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                                    : SvgPicture.asset(
                                  "assets/icons/marker_big.svg",
                                  width: 80,
                                  height: 100,
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mapData
                                          .destinationLocationPlaceName
                                          .toString(),
                                      style: const TextStyle(
                                        fontFamily: "SF Pro Display",
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.visible,
                                    ),
                                    Text(
                                      mapData
                                          .destinationLocationAddress
                                          .toString(),
                                      style: const TextStyle(
                                        fontFamily: "SF Pro Display",
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                        text:
                                        "https://maps.app.goo.gl/" +
                                            mapData
                                                .destinationID));
                                  },
                                  icon: Icon(Icons.share_rounded)),
                              FilledButton(
                                onPressed: () {
                                  calcRouteFromDepToDes();
                                },
                                child: const Text("Chỉ đường"),
                              ),
                              IconButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                        text:
                                        "https://maps.app.goo.gl/" +
                                            mapData
                                                .destinationID));
                                  },
                                  icon: Icon(Icons.bookmark)),
                            ],
                          )
                        ]),
                      ),
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
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 20.0),
                          child: Column(children: <Widget>[
                            const Pill(),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                  child: SvgPicture.asset(
                                    "assets/icons/marker_big.svg",
                                    width: 80,
                                    height: 100,
                                    fit: BoxFit.scaleDown,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Địa điểm không xác định",
                                        style: const TextStyle(
                                          fontFamily:
                                          "SF Pro Display",
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                        overflow:
                                        TextOverflow.visible,
                                      ),
                                      Text(
                                        mapData.destinationLocationLatLgn!
                                            .latitude
                                            .toString()
                                            .substring(0, 8) +
                                            ", " +
                                            mapData
                                                .destinationLocationLatLgn!
                                                .longitude
                                                .toString()
                                                .substring(0, 8),
                                        style: const TextStyle(
                                          fontFamily:
                                          "SF Pro Display",
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        overflow:
                                        TextOverflow.visible,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            FilledButton(
                              onPressed: () {
                                calcRoute(
                                    from: mapData
                                        .departureLocation!,
                                    to: mapData
                                        .destinationLocationLatLgn!);
                              },
                              child: const Text("Chỉ đường"),
                            ),
                          ]),
                        ),
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
                        RoutePlanningListTile(
                          route: routes[0],
                          travelMode: travelMode,
                          isAvoidTolls: isAvoidTolls,
                          isAvoidHighways: isAvoidHighways,
                          isAvoidFerries: isAvoidFerries,
                          waypointsLatLgn: waypointsLatLgn,
                          destinationLatLgn: mapData
                              .destinationLocationLatLgn!,
                        )
                        // RoutePlanningList(
                        //     routes: routes,
                        //     travelMode: travelMode,
                        //     isAvoidTolls: isAvoidTolls,
                        //     isAvoidHighways: isAvoidHighways,
                        //     isAvoidFerries: isAvoidFerries,
                        //     waypointsLatLgn: waypointsLatLgn,
                        //     destinationLatLgn:
                        //         mapData.destinationLocation!,
                        //     itemClick: (index) {
                        //       //changeState("Navigation");
                        //     })
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
                              child:
                              Column(children: <Widget>[
                                const Pill(),
                                EndLocationList(
                                  onLongPress:
                                      (LatLng latlng) {
                                    animateToPosition(
                                        latlng,
                                        zoom: 17);
                                  },
                                  legs: routes[0].legs,
                                  controller:
                                  _listviewScrollController,
                                )
                              ]))));
                })
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
                        Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.green,
                            ),
                            const SizedBox(
                              height: 34,
                            ),
                            FilledButton(
                              onPressed: () {
                                calcRoute(
                                    from: mapData
                                        .departureLocation ??
                                        mapData
                                            .currentLocation!,
                                    to: mapData
                                        .destinationLocationLatLgn!);
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
                                                      logWithTag("Waypoint Name: $value", tag: "Add Waypoint");
                                                    });
                                                  });
                                                  myMarker.add(Marker(
                                                    markerId: MarkerId(centerLocation.toString()),
                                                    icon: (myMarker.length < waypointMarkers.length) ? waypointMarkers[(myMarker.length - 1)] : waypointMarkers[waypointMarkers.length - 1],
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
                                    controller:
                                    _listviewScrollController,
                                    markerList:
                                    myMarker,
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
                            SizedBox(
                              height: 40,
                            ),
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
