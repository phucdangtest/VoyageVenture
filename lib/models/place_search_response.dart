import 'dart:convert';

import 'package:voyageventure/models/place_search.dart';

class placeSeachResponse {
  final String? status;
  final List<placeSearch>? places;

  placeSeachResponse({this.status, this.places});

  factory placeSeachResponse.fromJson(Map<String, dynamic> json) {
    return placeSeachResponse(
      status: json['status'] as String?,
      places: json['places'] != null
          ? (json['places'] as List)
          .map((item) => placeSearch.fromJson(item))
          .toList()
          : null,
    );
  }


  static placeSeachResponse parseAutocompleteResult(
      String responseBody) {
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return placeSeachResponse.fromJson(parsed);
  }
}