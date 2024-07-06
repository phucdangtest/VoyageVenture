import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:voyageventure/models/route_calculate_response.dart';

import '../utils.dart';

class EndLocationList extends StatefulWidget {

  ScrollController controller;
  List<Leg_> legs;
  Function(LatLng) onLongPress;

  EndLocationList({super.key, required this.controller, required this.legs, required this.onLongPress});

  @override
  State<EndLocationList> createState() => _EndLocationListState();

}
class _EndLocationListState extends State<EndLocationList> {
  List<LatLng> endLocations = [];
  List<String> endLocationsName = [];
  List<String> distance = [];
  List<String> navigation = [];
  int selectedEndLocation = -1;

  // Function to convert an index to a letter
  String indexToLetter(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }
  @override
  void initState() {
    super.initState();
    updateAllLists();


  }

  @override
void didUpdateWidget(covariant EndLocationList oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.legs != oldWidget.legs) {
     updateAllLists();
  }
}

void updateAllLists() {
    setState(() {
      endLocations.clear();
      endLocationsName.clear();
      distance.clear();
      navigation.clear();

      for (Step_ step in widget.legs[0].steps!) {
        endLocations.add(step.endLocation.latLng);
        endLocationsName.add(step.endLocationAddress ?? "");
        distance.add(step.GetRoundedDistanceMeters().toString() + "m");
        navigation.add(step.navigationInstruction.maneuver);
      }
    });

}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      height: 200,
      child: ListView.builder(
        itemCount: endLocations.length,
        itemBuilder: (context, index) {
          // Calculate the reversed index
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38, width: 2),
            ),
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (selectedEndLocation == index)? Color.fromARGB(100, 187, 187, 187): Colors.white,
                    ),
                    child: GestureDetector(
                      onLongPress: () {
                        widget.onLongPress(endLocations[index]);
                        setState(() {
                          selectedEndLocation = index;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((index + 1).toString() + " - " + navigation[index] + " - " + distance[index],
                            style: const TextStyle(
                              fontFamily: "SF Pro Display",
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),), // Use the function here
                          if (endLocationsName.length == endLocations.length) Text(endLocationsName[index],
                              style: const TextStyle(
                                fontFamily: "SF Pro Display",
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(LatLngToString(endLocations[index]),
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
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }


}