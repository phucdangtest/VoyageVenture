import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voyageventure/components/route_planning_list_tile.dart';
import 'package:voyageventure/utils.dart';
import '../models/route_calculate.dart';
import '../models/route_calculate_response.dart';

class RoutePlanningList extends StatefulWidget {
  final List<Route_> routes;
  final Function(int) itemClick;
  final String travelMode;
  final List<LatLng> waypointsLatLgn;
  final LatLng destinationLatLgn;

  final bool isAvoidTolls;
  final bool isAvoidHighways;
  final bool isAvoidFerries;

  RoutePlanningList(
      {super.key,
      required this.routes,
      required this.itemClick,
      required String this.travelMode,
        required this.isAvoidTolls,
        required this.isAvoidHighways,
        required this.isAvoidFerries,
      required this.waypointsLatLgn,
      required this.destinationLatLgn
      });

  @override
  State<RoutePlanningList> createState() => _RoutePlanningListState();
}

class _RoutePlanningListState extends State<RoutePlanningList> {
  //late Future<List<Route_>?> routes;
  // Route_? routesCurrent;
  // final LatLng currentLocation = const LatLng(10.8803443, 106.808288);
  // final LatLng cnttLocation = const LatLng(10.8022349,106.6695118);
  // final LatLng currentLocation = const LatLng(42.340173523716736, -71.05997968330408);
  // final LatLng cnttLocation = const LatLng(42.075698891472804, -72.59806562080408);

  @override
  initState() {
    super.initState();
    // computeRoutesReturnRoute_(from: currentLocation, to: cnttLocation).then((value) => {
    //   setState(() {
    //     routesCurrent = value!.first;
    //     logWithTag(routesCurrent.toString(), tag:'RoutePlanningList');
    //   })
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Container(
          //   width: 100,
          //   height: 100,
          //   child: FloatingActionButton(onPressed: (){setState(() {
          //
          //   });}),
          // ),
          GestureDetector(
            onTap: () async {

              String travelModeParameter = '';
              String waypointsParameter = '';
              String avoidParameter = '';

              if (widget.isAvoidTolls || widget.isAvoidHighways || widget.isAvoidFerries) {
                avoidParameter += "&avoid=";
                if (widget.isAvoidTolls)
                  avoidParameter += "t";
                if (widget.isAvoidHighways)
                  avoidParameter += "h";
                if (widget.isAvoidFerries)
                  avoidParameter += "f";
              }

              if (widget.travelMode == "TWO_WHEELER")
                travelModeParameter = "&mode=l";
              else if (widget.travelMode == "WALK")
                travelModeParameter = "&mode=w";


              for (int i = 0; i < widget.waypointsLatLgn.length; i++) {
                if (i == 0)
                  waypointsParameter += "&waypoints=";

                waypointsParameter += LatLngToString(widget.waypointsLatLgn[i]);

                if (i != widget.waypointsLatLgn.length - 1)
                  waypointsParameter += "%7C";

              }
              logWithTag('google.navigation:q='
                  '${LatLngToString(widget.destinationLatLgn)}'
                  '${waypointsParameter}'
                  '${travelModeParameter}'
                  '${avoidParameter}'
                  , tag: 'Launch URL');


              await launchUrl(Uri.parse(
                  'google.navigation:q='
                      '${LatLngToString(widget.destinationLatLgn)}'
                      '${waypointsParameter}'
                      '${travelModeParameter}'
                      '${avoidParameter}'
              ));
            },
            child: Container(
              width: double.infinity,
              height: 500,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.routes[0].getLegsCount(),
                itemBuilder: (context, index) {
                  return RoutePlanningListTile(
                      leg: widget.routes[0].getLeg(index),
                      travelMode: widget.travelMode);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
