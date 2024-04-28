import 'package:flutter/material.dart';

class Pill extends StatefulWidget {
  const Pill({super.key});

  @override
  State<Pill> createState() => _PillState();
}

class _PillState extends State<Pill> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.0),
      height: 4.0,
      width: 40.0,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius:
        const BorderRadius.all(Radius.circular(15.0)),
      ),
    );
  }
}
