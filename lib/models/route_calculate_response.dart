import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

