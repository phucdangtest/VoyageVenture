import 'dart:convert';

import 'package:voyageventure/models/place_search.dart';
import 'package:voyageventure/utils.dart';

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

  String getShortPlaces() {
    return places?.map((place) => (place.displayName?.text) ?? '').join('\n') ?? '';
  }

  static PlaceSearchResponse_ parsePlaceSearchResult(
      String responseBody) {
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return PlaceSearchResponse_.fromJson(parsed);
  }
  @override
  String toString(){
    return 'PlaceSearchResponse_ { status: $status, places:\n${getShortPlaces()} }';
  }

}

class PlaceSearchResponseSingle_ {
  final String? status;
  final PlaceSearch_? place;

  PlaceSearchResponseSingle_({this.status, this.place});

  factory PlaceSearchResponseSingle_.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResponseSingle_(
      status: json['status'] as String?,
      place: json['places'] != null
          ? PlaceSearch_.fromJson((json['places'] as List).first)
          : null,
    );
  }

  String getShortPlace() {
    return place?.displayName?.text ?? '';
  }

  static PlaceSearchResponseSingle_ parsePlaceSearchResult(
      String responseBody) {
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return PlaceSearchResponseSingle_.fromJson(parsed);
  }

  @override
  String toString(){
    return 'PlaceSearchResponseSingle_ { status: $status, place: ${getShortPlace()}, location: ${place?.location.toString()}';
  }
}