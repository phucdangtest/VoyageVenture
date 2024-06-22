import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/components/route_planning_list_tile.dart';
import 'package:voyageventure/utils.dart';
import '../models/route_calculate.dart';
import '../models/route_calculate_response.dart';

class RoutePlanningList extends StatefulWidget {
  final List<Route_> routes;
  final Function(int) itemClick;
  final String travelMode;
  const RoutePlanningList({super.key, required this.routes, required this.itemClick, required String this.travelMode});

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
          onTap: () {
            widget.itemClick(0);
          },
         child: Container(
            width: double.infinity,
            height: 500,
            child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.routes[0].getLegsCount(),
            itemBuilder: (context, index) {
              return RoutePlanningListTile(leg: widget.routes[0].getLeg(index), travelMode: widget.travelMode);
            },
            ),
          ),
       )
      ],
    ),
  );
}
}
