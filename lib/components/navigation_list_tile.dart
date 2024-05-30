import 'package:flutter/material.dart';

class NavigationListTile extends StatelessWidget {
  const NavigationListTile ({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.navigation, // You can replace this icon with an upward arrow
            color: Colors.blue,
          ),
          Text(
            'Head northeast',
            style: TextStyle(
              fontSize: 12.0,
            ),
          ),
        ],
      ),
      title: Text(
        '20 m',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text('Turn right'),
    );


  }
}
