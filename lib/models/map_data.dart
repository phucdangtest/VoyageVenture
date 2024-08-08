
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/models/place_search.dart';

import '../utils.dart';

class MapData {
  LatLng? currentLocation;
  LatLng? departureLocation;
  String departureLocationName;
  LatLng? destinationLocationLatLgn;
  String destinationLocationAddress;
  String destinationLocationPlaceName;
  String destinationLocationPhotoUrl;
  String destinationID = "";

  MapData({
    this.currentLocation,
    this.departureLocation,
    this.destinationLocationLatLgn,
    this.departureLocationName = "Vị trí hiện tại",
    this.destinationLocationAddress = "",
    this.destinationLocationPlaceName = "",
    this.destinationLocationPhotoUrl = "",
  });

  void changeDestinationLocationLatLgn(LatLng latLng) {
    destinationLocationLatLgn = latLng;
    logWithTag("Destination location changed to: $latLng", tag: "MapData");
    logWithTag(
        "All data: $currentLocation, $departureLocation, $destinationLocationLatLgn",
        tag: "MapData");
    // Future<String?> placeString = convertLatLngToAddress(latLng);
    // placeString.then((value) {
    //   destinationLocationName = value ?? "Không có chi tiết";
    //   logWithTag("Destination location changed to: $value + $latLng",
    //       tag: "MapData");
    // });
  }

  void changeDepartureLocation(LatLng from) {
    departureLocation = from;
    logWithTag("Departure location changed to: $from", tag: "MapData");
    logWithTag(
        "All data: $currentLocation, $departureLocation, $destinationLocationLatLgn",
        tag: "MapData");

    // Future<String?> placeString = convertLatLngToAddress(from);
    // placeString.then((value) {
    //   departureLocationName = value ?? "Không có chi tiết";
    //   logWithTag("Departure location changed to: $value + $from",
    //       tag: "MapData");
    // });
  }

  void changeCurrentLocation(LatLng value) {
    currentLocation = value;
    logWithTag("Current location changed to: $value", tag: "MapData");
    logWithTag(
        "All data: $currentLocation, $departureLocation, $destinationLocationLatLgn",
        tag: "MapData");
  }

  void changeDestinationLocationAddress(String value) {
    destinationLocationAddress = value;
    logWithTag("Destination location name changed to: $value", tag: "MapData");
  }

  void changeDestinationLocationPlaceName(String value) {
    destinationLocationPlaceName = value;
    logWithTag("Destination location name changed to: $value", tag: "MapData");
  }

  void changeDestinationAddressAndPlaceNameAndImage(PlaceSearch_ place) {
    destinationID = place.id!;
    destinationLocationAddress = place.formattedAddress!;
    destinationLocationPlaceName = place.displayName?.text ?? "";
    if (place.photoUrls != null) destinationLocationPhotoUrl = place.photoUrls!;
    logWithTag(place.toString(), tag: "MapData info");
    logWithTag(
        "Destination location name changed to: $destinationLocationPlaceName",
        tag: "MapData");
    logWithTag(
        "Destination location address changed to: $destinationLocationAddress",
        tag: "MapData");
  }

  void changeDestinationImage(String value) {
    destinationLocationPhotoUrl = value;
    logWithTag("Destination location image changed to: $value", tag: "MapData");
  }
}
