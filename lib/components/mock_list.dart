import 'package:flutter/material.dart';

import 'location_list_tile.dart';
class MockList_ extends StatefulWidget {
  ScrollController controller;
  MockList_({Key? key, required this.controller}) : super(key: key);

  @override
  State<MockList_> createState() => _MockList_State();
}

class _MockList_State extends State<MockList_> {
  int itemCount = 3;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        return LocationListTile_(
          press: () {
            setState(() {
              itemCount++; // Increment the number of items when a tile is pressed
            });
          },
          location: "Location ${index + 1}",
          placeName: 'Place Name ${index + 1}',
        );
      },
    );
  }
}
