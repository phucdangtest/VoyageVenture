import 'package:flutter/material.dart';

import 'location_list_tile.dart';
class MockList_ extends StatefulWidget {
  const MockList_({super.key});

  @override
  State<MockList_> createState() => _MockList_State();
}

class _MockList_State extends State<MockList_> {
  int itemCount = 3;
  PageController _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: itemCount,
      onPageChanged: (index) {
        // Update the BottomSheet when the page changes
      },
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
