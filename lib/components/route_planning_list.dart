import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/components/route_planning_list_tile.dart';
import 'package:voyageventure/utils.dart';
import '../models/route_calculate.dart';
import '../models/route_calculate_response.dart';

class RoutePlanningList extends StatefulWidget {
  const RoutePlanningList({super.key});

  @override
  State<RoutePlanningList> createState() => _RoutePlanningListState();
}

class _RoutePlanningListState extends State<RoutePlanningList> {
  //late Future<List<Route_>?> routes;
  Route_? routesCurrent;
  final LatLng currentLocation = const LatLng(10.8803443, 106.808288);
  final LatLng cnttLocation = const LatLng(10.8022349,106.6695118);
  // final LatLng currentLocation = const LatLng(42.340173523716736, -71.05997968330408);
  // final LatLng cnttLocation = const LatLng(42.075698891472804, -72.59806562080408);

  @override
  initState() {
    super.initState();
    computeRoutesReturnRoute_(from: currentLocation, to: cnttLocation).then((value) => {
      setState(() {
        routesCurrent = value!.first;
        logWithTag(routesCurrent.toString(), tag:'RoutePlanningList');
      })
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Text('Route Planning List'),
        ],
      ),
    ),
    body: Column(
      children: [
        Container(
          width: 100,
          height: 100,
          child: FloatingActionButton(onPressed: (){setState(() {

          });}),
        ),
        routesCurrent != null? Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          width: double.infinity,
          height: 500,
          child: ListView.builder(
          shrinkWrap: true,
          itemCount: routesCurrent?.getLegsCount(),
          itemBuilder: (context, index) {
            return RoutePlanningListTile(leg: routesCurrent!.getLeg(index));
          },
          ),
        ) :
        Container(
          width: double.infinity,
          height: 500,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        )
      ],
    ),
  );
}
}
