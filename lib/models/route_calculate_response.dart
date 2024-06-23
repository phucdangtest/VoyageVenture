import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/utils.dart';

class RouteResponse_ {
  List<Route_> routes;

  RouteResponse_({required this.routes});

  factory RouteResponse_.fromJson(Map<String, dynamic> json){
    return RouteResponse_(
      routes: (json['routes'] as List)
          .map((item) => Route_.fromJson(item))
          .toList(),
    );
  }
  @override
  String toString()
  {
    String stringReturn = '';
    for (Route_ route in routes)
    {
      stringReturn += route.toString() + "\n";
    }
    return stringReturn;
  }

  Route_ getRoute(int index) {
    return routes[index];
  }
}

class Route_ {
  List<Leg_> legs;

  Route_({required this.legs});

  factory Route_.fromJson(Map<String, dynamic> json){
    return Route_(
      legs: (json['legs'] as List).map((item) => Leg_.fromJson(item)).toList(),
    );
  }

  @override
  String toString() {
    return 'Route_ { legs: ${legs.toString()} }';
  }

  Leg_ getLeg(int index) {
    return legs[index];
  }

  int getLegsCount() {
    return legs.length;
  }
}

class Leg_ {
  int distanceMeters;
  String duration;
  String staticDuration;
  Polyline_ polyline;
  Location_ startLocation;
  Location_ endLocation;
  List<Step_> steps;

  Leg_(
      {required this.distanceMeters, required this.duration, required this.staticDuration, required this.polyline, required this.startLocation, required this.endLocation, required this.steps});

  factory Leg_.fromJson(Map<String, dynamic> json){
    return Leg_(
      distanceMeters: json['distanceMeters'],
      duration: json['duration'],
      staticDuration: json['staticDuration'],
      polyline: Polyline_.fromJson(json['polyline']),
      startLocation: Location_.fromJson(json['startLocation']),
      endLocation: Location_.fromJson(json['endLocation']),
      steps: (json['steps'] as List)
          .map((item) => Step_.fromJson(item))
          .toList(),
    );
  }

  String getDistanceMeters() {
    return distanceMeters.toString();
  }

  String getDistanceMetersInKm() {
    return (distanceMeters / 1000).toStringAsFixed(1) + ' km';
  }

  String getDuration() {
    return duration;
  }

  String getDurationFormat() {
    return convertDurationToMinutesOrHoursAndMinutes(duration);
  }

  String convertDurationToMinutesOrHoursAndMinutes(String durationString) {
    int duration = int.parse(durationString.replaceAll('s', ''));
    int hours = duration ~/ 3600;
    int minutes = (duration % 3600) ~/ 60;
    if (hours == 0) {
      return '$minutes phút';
    }
    return '$hours' + 'h $minutes'+ 'p';
  }

  String getStaticDuration() {
    return staticDuration;
  }

  String getStaticDurationFormat() {
    return convertDurationToMinutesOrHoursAndMinutes(staticDuration);
  }

  String getDifferenceDuration() {
    int durationInt = int.parse(duration.replaceAll('s', ''));
    int staticDurationInt = int.parse(staticDuration.replaceAll('s', ''));
    int difference = (durationInt - staticDurationInt).abs();
    return convertDurationToMinutesOrHoursAndMinutes(difference.toString());
  }

  Polyline_ getPolyline() {
    return polyline;
  }
  Location_ getStartLocation() {
    return startLocation;
  }
  Location_ getEndLocation() {
    return endLocation;
  }
  List<Step_> getSteps() {
    return steps;
  }

  @override
  String toString() {
    return 'Leg_ { distanceMeters: $distanceMeters, duration: $duration, staticDuration: $staticDuration, polyline: ${polyline.encodedPolyline}, startLocation: ${startLocation.latLng}, endLocation: ${endLocation.latLng}, steps: ${steps.toString()} }';
  }
}

class Polyline_ {
  String encodedPolyline;

  Polyline_({required this.encodedPolyline});

  factory Polyline_.fromJson(Map<String, dynamic> json){
    return Polyline_(
      encodedPolyline: json['encodedPolyline'],
    );
  }

  static List<LatLng> decodePolyline(encodedPolyline) {
    List<LatLng> points = <LatLng>[];
    int index = 0, len = encodedPolyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng(lat / 1E5, lng / 1E5);
      points.add(p);
    }

    return points;
  }
}

class Location_ {
  LatLng latLng;

  Location_({required this.latLng});

  factory Location_.fromJson(Map<String, dynamic> json){
    return Location_(
      latLng: LatLng(json['latLng']['latitude'], json['latLng']['longitude']),
    );
  }
}

class Step_ {
  int distanceMeters;
  String staticDuration;
  Polyline_ polyline;
  Location_ startLocation;
  Location_ endLocation;
  NavigationInstruction_ navigationInstruction;
  LocalizedValues_ localizedValues;
  String travelMode;

  Step_(
      {required this.distanceMeters, required this.staticDuration, required this.polyline, required this.startLocation, required this.endLocation, required this.navigationInstruction, required this.localizedValues, required this.travelMode});
  factory Step_.fromJson(Map<String, dynamic> json) {
    return Step_(
      distanceMeters: json['distanceMeters'],
      staticDuration: json['staticDuration'],
      polyline: Polyline_.fromJson(json['polyline']),
      startLocation: Location_.fromJson(json['startLocation']),
      endLocation: Location_.fromJson(json['endLocation']),
      navigationInstruction: NavigationInstruction_.fromJson(json['navigationInstruction']),
      localizedValues: LocalizedValues_.fromJson(json['localizedValues']),
      travelMode: json['travelMode'],
    );
  }

  @override
  String toString() {
    return 'Step_ { distanceMeters: $distanceMeters, staticDuration: $staticDuration, polyline: ${polyline.encodedPolyline}, startLocation: ${startLocation.latLng}, endLocation: ${endLocation.latLng}, navigationInstruction: ${navigationInstruction.instructions}, ${navigationInstruction.maneuver}, localizedValues: ${localizedValues.distance}, ${localizedValues.staticDuration}, travelMode: $travelMode }';
  }
}

class NavigationInstruction_ {
  String maneuver;
  String instructions;

  NavigationInstruction_({required this.maneuver, required this.instructions});

  factory NavigationInstruction_.fromJson(Map<String, dynamic> json) {
    return NavigationInstruction_(
      maneuver: json['maneuver'],
      instructions: json['instructions'],
    );
  }
}

class LocalizedValues_ {
  String distance;
  String staticDuration;

  LocalizedValues_({required this.distance, required this.staticDuration});

  factory LocalizedValues_.fromJson(Map<String, dynamic> json) {
    return LocalizedValues_(
      distance: json['distance']['text'],
      staticDuration: json['staticDuration']['text'],
    );
  }
}

