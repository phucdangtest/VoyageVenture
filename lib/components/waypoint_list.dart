import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';

import '../utils.dart';

class WaypointList extends StatefulWidget {
  List<LatLng> waypoints;

  List<String> waypointsName;
  ScrollController controller;

  WaypointList({super.key, required this.waypoints, required this.waypointsName, required this.controller});

  @override
  State<WaypointList> createState() => _WaypointListState();
}
class _WaypointListState extends State<WaypointList> {
  // Function to convert an index to a letter
  String indexToLetter(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      itemCount: widget.waypoints.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        // Calculate the reversed index
        int reversedIndex = widget.waypoints.length - 1 - index;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(indexToLetter(reversedIndex)), // Use the function here
                  Text(LatLngToString(widget.waypoints[reversedIndex])),
                  if (widget.waypointsName.length == widget.waypoints.length) Text(widget.waypointsName[reversedIndex]),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward),
              onPressed: () {
                if (reversedIndex != widget.waypoints.length - 1) {
                  setState(() {
                    changePositionWaypoints(reversedIndex, reversedIndex + 1, widget.waypoints);
                    changePositionWaypointName(reversedIndex, reversedIndex + 1, widget.waypointsName);
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: () {
                if (reversedIndex != 0) {
                  setState(() {
                    changePositionWaypoints(reversedIndex, reversedIndex - 1, widget.waypoints);
                    changePositionWaypointName(reversedIndex, reversedIndex - 1, widget.waypointsName);
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  widget.waypoints.removeAt(reversedIndex);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void changePositionWaypoints(int reversedIndex, int i, List<LatLng> waypoints) {
    var temp = waypoints[reversedIndex];
    waypoints[reversedIndex] = waypoints[i];
    waypoints[i] = temp;
  }

  void changePositionWaypointName(int reversedIndex, int i, List<String> waypointName) {
    var temp = waypointName[reversedIndex];
    waypointName[reversedIndex] = waypointName[i];
    waypointName[i] = temp;
  }



}