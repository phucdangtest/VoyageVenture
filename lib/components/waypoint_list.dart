import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';

import '../utils.dart';

class WaypointList extends StatefulWidget {
  List<LatLng> waypoints;
  WaypointList({super.key, required this.waypoints});

  @override
  State<WaypointList> createState() => _WaypointListState();
}
class _WaypointListState extends State<WaypointList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.waypoints.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Row(
          children: [
            Container(
              child: Column(
                children: [
                  Text('Không tên'),
                  Text(LatLngToString(widget.waypoints[index])),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward),
              onPressed: () {
                if (index != 0) {
                  setState(() {
                    var temp = widget.waypoints[index];
                    widget.waypoints[index] = widget.waypoints[index - 1];
                    widget.waypoints[index - 1] = temp;
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: () {
                if (index != widget.waypoints.length - 1) {
                  setState(() {
                    var temp = widget.waypoints[index];
                    widget.waypoints[index] = widget.waypoints[index + 1];
                    widget.waypoints[index + 1] = temp;
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  widget.waypoints.removeAt(index);
                });
              },
            ),
          ],
        );
      },
    );
  }
}