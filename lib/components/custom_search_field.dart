import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/place_autocomplete.dart';
import '../models/place_search.dart';

class CustomSearchField extends StatefulWidget {
  final Function(String) onSubmitted;
  final Function(String) onChanged;
  final Function() onNearbySearchButtonPressed;
  List<PlaceAutocomplete_> placeAutoList = [];
  List<PlaceSearch_> placeSearchList = [];
  CustomSearchField({required this.onSubmitted, required this.onChanged, required this.onNearbySearchButtonPressed ,required this.placeAutoList, required this.placeSearchList});

  @override
  _CustomSearchFieldState createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
     );
  }
}