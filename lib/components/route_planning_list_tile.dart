import 'package:flutter/material.dart';

class RoutePlanningListTile extends StatelessWidget {
  const RoutePlanningListTile ({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
        child: Icon(
          Icons.navigation,
          color: Colors.white,
        ),
      ),
      title: Text(
        '5 min (1.9 km)',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'Fastest route now due to traffic conditions',
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.more_vert),
        onPressed: () => {},
      ),
    );

  }
}
