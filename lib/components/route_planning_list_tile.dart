import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voyageventure/models/route_calculate_response.dart';
import 'package:voyageventure/utils.dart';

class RoutePlanningListTile extends StatelessWidget {
  late Leg_ leg;
  late String travelMode;
  RoutePlanningListTile({super.key, required this.leg, required String this.travelMode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color.fromARGB(255, 246, 245, 245),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.getStaticDurationFormat(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                leg.getDifferenceDuration().startsWith("0")
                    ? Text(
                        "Giao thông thưa thớt ",
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      )
                    : Text(
                        "Chậm hơn ${leg.getDifferenceDuration()} so với bình thường",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                Text("Đi qua Xa lộ Hà Nội",
                    style: TextStyle(fontSize: 12, color: Colors.black)),
                Row(
                  children: [
                    travelMode == "DRIVE"
                        ? SvgPicture.asset(
                            "assets/icons/car.svg",
                          )
                        : travelMode == "WALK"
                            ? SvgPicture.asset(
                                "assets/icons/walk.svg",
                              )
                            : travelMode == "TWO_WHEELER"
                                ? SvgPicture.asset(
                                    "assets/icons/motor.svg",
                                  )
                                : SvgPicture.asset(
                                    "assets/icons/public_transport.svg",
                                  ),

                    SizedBox(width: 5),
                    Text(
                      leg.getDistanceMetersInKm(),
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            IconButton(
                onPressed: () {},
                icon: SvgPicture.asset(
                  "assets/icons/map-arrow-up.svg",
                ))
          ],
        ),
      ),
    );
  }
}
