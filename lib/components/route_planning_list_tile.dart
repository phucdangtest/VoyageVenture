import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voyageventure/models/route_calculate_response.dart';
import 'package:voyageventure/utils.dart';

class RoutePlanningListTile extends StatelessWidget {
  late Leg_ leg;

  RoutePlanningListTile({super.key, required this.leg});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

        ),
        child: Column(
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
                    "Bao gồm " + leg.getDifferenceDuration() + " theo tình trạng giao thông",
                    style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                  )
            ,
            Container(
              height: 50,
              width: 130,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 236, 234),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    "assets/icons/car.svg",
                  ),
                  Text(
                    leg.getDistanceMetersInKm(),
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      trailing: SvgPicture.asset(
        "assets/icons/arrow_right.svg"),
    );
  }
}
