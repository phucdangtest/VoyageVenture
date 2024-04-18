import 'dart:convert';

import 'package:voyageventure/models/place_search.dart';

class PlaceSearchResponse_ {
  final String? status;
  final List<PlaceSearch_>? places;

  PlaceSearchResponse_({this.status, this.places});

  factory PlaceSearchResponse_.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResponse_(
      status: json['status'] as String?,
      places: json['places'] != null
          ? (json['places'] as List)
          .map((item) => PlaceSearch_.fromJson(item))
          .toList()
          : null,
    );
  }


  static PlaceSearchResponse_ parsePlaceSearchResult(
      String responseBody) {
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return PlaceSearchResponse_.fromJson(parsed);
  }
}