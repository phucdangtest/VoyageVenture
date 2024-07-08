import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voyageventure/models/route_calculate_response.dart';
import 'package:voyageventure/utils.dart';
//
// class RoutePlanningListTile extends StatelessWidget {
//   late Route_ route;
//   late String travelMode;
//   late List<LatLng> waypointsLatLgn;
//   late LatLng destinationLatLgn;
//   late bool isAvoidTolls;
//   late bool isAvoidHighways;
//   late bool isAvoidFerries;
//
//
//   RoutePlanningListTile(
//       {super.key, required this.route, required String this.travelMode,
//         required this.isAvoidTolls,
//         required this.isAvoidHighways,
//         required this.isAvoidFerries,
//       required this.waypointsLatLgn,
//       required this.destinationLatLgn
//       });
//
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             bottom: BorderSide(
//               color: Color.fromARGB(255, 246, 245, 245),
//               width: 1.0,
//             ),
//           ),
//         ),
//         child: Row(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   route.getCombinedStaticDurationFormat(),
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(width: 5),
//                 route.getCombinedDifferenceDuration().startsWith("0")
//                     ? Text(
//                         "Giao thông thưa thớt ",
//                         style: TextStyle(fontSize: 12, color: Colors.green),
//                       )
//                     : Text(
//                         "Chậm hơn ${route.getCombinedDifferenceDuration()} so với bình thường",
//                         style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.red,
//                             fontWeight: FontWeight.bold),
//                       ),
//                 Text("Đi qua Xa lộ Hà Nội",
//                     style: TextStyle(fontSize: 12, color: Colors.black)),
//                 Row(
//                   children: [
//                     travelMode == "DRIVE"
//                         ? SvgPicture.asset(
//                             "assets/icons/car.svg",
//                           )
//                         : travelMode == "WALK"
//                             ? SvgPicture.asset(
//                                 "assets/icons/walk.svg",
//                               )
//                             : travelMode == "TWO_WHEELER"
//                                 ? SvgPicture.asset(
//                                     "assets/icons/motor.svg",
//                                   )
//                                 : SvgPicture.asset(
//                                     "assets/icons/public_transport.svg",
//                                   ),
//                     SizedBox(width: 5),
//                     Text(
//                       route.getCombinedDistanceMetersInKm(),
//                       style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             Spacer(),
//             IconButton(
//                 onPressed: () async {
//                   String travelModeParameter = '';
//                   String waypointsParameter = '';
//                   String avoidParameter = '';
//
//                   if (widget.isAvoidTolls ||
//                       widget.isAvoidHighways ||
//                       widget.isAvoidFerries) {
//                     avoidParameter += "&avoid=";
//                     if (widget.isAvoidTolls) avoidParameter += "t";
//                     if (widget.isAvoidHighways) avoidParameter += "h";
//                     if (widget.isAvoidFerries) avoidParameter += "f";
//                   }
//
//                   if (widget.travelMode == "TWO_WHEELER")
//                     travelModeParameter = "&mode=l";
//                   else if (widget.travelMode == "WALK")
//                     travelModeParameter = "&mode=w";
//
//                   for (int i = 0; i < widget.waypointsLatLgn.length; i++) {
//                     if (i == 0) waypointsParameter += "&waypoints=";
//
//                     waypointsParameter +=
//                         LatLngToString(widget.waypointsLatLgn[i]);
//
//                     if (i != widget.waypointsLatLgn.length - 1)
//                       waypointsParameter += "%7C";
//                   }
//                   logWithTag(
//                       'google.navigation:q='
//                       '${LatLngToString(widget.destinationLatLgn)}'
//                       '${waypointsParameter}'
//                       '${travelModeParameter}'
//                       '${avoidParameter}',
//                       tag: 'Launch URL');
//
//                   await launchUrl(Uri.parse('google.navigation:q='
//                       '${LatLngToString(widget.destinationLatLgn)}'
//                       '${waypointsParameter}'
//                       '${travelModeParameter}'
//                       '${avoidParameter}'));
//                 },
//                 icon: SvgPicture.asset(
//                   "assets/icons/map-arrow-up.svg",
//                 ))
//           ],
//         ),
//       ),
//     );
//   }
// }

class RoutePlanningListTile extends StatefulWidget {
  final Route_ route;
  final String travelMode;
  final List<LatLng> waypointsLatLgn;
  final LatLng destinationLatLgn;
  final bool isAvoidTolls;
  final bool isAvoidHighways;
  final bool isAvoidFerries;

  RoutePlanningListTile({
    super.key,
    required this.route,
    required this.travelMode,
    required this.isAvoidTolls,
    required this.isAvoidHighways,
    required this.isAvoidFerries,
    required this.waypointsLatLgn,
    required this.destinationLatLgn
  });

  @override
  State<RoutePlanningListTile> createState() => _RoutePlanningListTileState();
}

class _RoutePlanningListTileState extends State<RoutePlanningListTile> {

  String longestRoute = '';
  int longestDistance = 0;
  int longestIndex = 0;

  @override
  void initState() {
    super.initState();
    List<Step_>? stepList = widget.route.legs[0].steps;
    if (stepList == null) return;
    for (int i = 0; i < stepList.length; i++) {
      if (stepList[i].distanceMeters > longestDistance) {
        String instruction = stepList[i].navigationInstruction.instructions;
        if (instruction.contains("Đ.")) {
          String s = instruction.substring(instruction.indexOf("Đ."));
          if (s.contains("Đi qua"))
            longestRoute = s.substring(0, s.indexOf("Đi qua") - 1);
          else
            longestRoute = instruction.substring(instruction.indexOf("Đ."));
        } else if (instruction.contains("Đường") && !instruction.contains("Đường bị giới hạn")) {
          String s = instruction.substring(instruction.indexOf("Đường"));
          if (s.contains("Đi qua"))
            longestRoute = s.substring(0, s.indexOf("Đi qua") - 1);
          else
            longestRoute = instruction.substring(instruction.indexOf("Đường"));
        }
        longestDistance = stepList[i].distanceMeters;
        longestIndex = i;
      }
    }
    if (longestRoute == '') longestRoute = stepList[longestIndex].navigationInstruction.instructions;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.route.getCombinedStaticDurationFormat(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  widget.route.getCombinedDifferenceDuration().startsWith("0")
                      ? Text(
                          "Giao thông thưa thớt ",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        )
                      : Text(
                          "Chậm hơn ${widget.route.getCombinedDifferenceDuration()} so với bình thường",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                  Text("Đi qua ${longestRoute}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.black)),
                  Row(
                    children: [
                      widget.travelMode == "DRIVE"
                          ? SvgPicture.asset(
                              "assets/icons/car.svg",
                            )
                          : widget.travelMode == "WALK"
                              ? SvgPicture.asset(
                                  "assets/icons/walk.svg",
                                )
                              : widget.travelMode == "TWO_WHEELER"
                                  ? SvgPicture.asset(
                                      "assets/icons/motor.svg",
                                    )
                                  : SvgPicture.asset(
                                      "assets/icons/public_transport.svg",
                                    ),
                      SizedBox(width: 5),
                      Text(
                        widget.route.getCombinedDistanceMetersInKm(),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
                onPressed: () async {
                  String travelModeParameter = '';
                  String waypointsParameter = '';
                  String avoidParameter = '';

                  if (widget.isAvoidTolls ||
                      widget.isAvoidHighways ||
                      widget.isAvoidFerries) {
                    avoidParameter += "&avoid=";
                    if (widget.isAvoidTolls) avoidParameter += "t";
                    if (widget.isAvoidHighways) avoidParameter += "h";
                    if (widget.isAvoidFerries) avoidParameter += "f";
                  }

                  if (widget.travelMode == "TWO_WHEELER")
                    travelModeParameter = "&mode=l";
                  else if (widget.travelMode == "WALK")
                    travelModeParameter = "&mode=w";

                  for (int i = 0; i < widget.waypointsLatLgn.length; i++) {
                    if (i == 0) waypointsParameter += "&waypoints=";

                    waypointsParameter +=
                        LatLngToString(widget.waypointsLatLgn[i]);

                    if (i != widget.waypointsLatLgn.length - 1)
                      waypointsParameter += "%7C";
                  }
                  logWithTag(
                      'google.navigation:q='
                      '${LatLngToString(widget.destinationLatLgn)}'
                      '${waypointsParameter}'
                      '${travelModeParameter}'
                      '${avoidParameter}',
                      tag: 'Launch URL');

                  await launchUrl(Uri.parse('google.navigation:q='
                      '${LatLngToString(widget.destinationLatLgn)}'
                      '${waypointsParameter}'
                      '${travelModeParameter}'
                      '${avoidParameter}'));
                },
                icon: SvgPicture.asset(
                  "assets/icons/map-arrow-up.svg",
                ))
          ],
        ),
      ),
    );
  }
}