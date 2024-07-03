import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';

import '../utils.dart';

class WaypointList extends StatefulWidget {
  List<LatLng> waypoints;

  List<String> waypointsName;
  ScrollController controller;
  List<Marker> markerList;

  WaypointList({super.key, required this.waypoints, required this.waypointsName, required this.controller, required this.markerList});

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

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 2),
          ),
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(indexToLetter(reversedIndex),
                      style: const TextStyle(
                        fontFamily: "SF Pro Display",
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),), // Use the function here
                    if (widget.waypointsName.length == widget.waypoints.length) Text(widget.waypointsName[reversedIndex],
                        style: const TextStyle(
                          fontFamily: "SF Pro Display",
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(LatLngToString(widget.waypoints[reversedIndex]),
                        style: const TextStyle(
                          fontFamily: "SF Pro Display",
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                    ),
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
                      changeMarkerIcon(reversedIndex, reversedIndex + 1, widget.markerList);
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
                      changeMarkerIcon(reversedIndex, reversedIndex - 1, widget.markerList);
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
          ),
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

  void changeMarkerIcon(int reversedIndex, int i, List<Marker> markerList) {
    var current = markerList[reversedIndex];
    var next = markerList[i];
    markerList[reversedIndex] = new Marker(markerId: next.markerId, position: next.position, icon: next.icon);
    markerList[i] = new Marker(markerId: current.markerId, position: current.position, icon: current.icon);
  }

}