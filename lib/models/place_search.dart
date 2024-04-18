class PlaceSearch_ {
  final String? id;
  final String? formattedAddress;
  final Location? location;
  final DisplayName? displayName;

  PlaceSearch_({
    this.id,
    this.formattedAddress,
    this.location,
    this.displayName,
  });

  factory PlaceSearch_.fromJson(Map<String, dynamic> json) {
    return PlaceSearch_(
      id: json['id'] as String?,
      formattedAddress: json['formattedAddress'] as String?,
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      displayName: json['displayName'] != null
          ? DisplayName.fromJson(json['displayName'])
          : null,
    );
  }
}

class Location {
  final double? latitude;
  final double? longitude;

  Location({this.latitude, this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }
}

class DisplayName {
  final String? text;
  final String? languageCode;

  DisplayName({this.text, this.languageCode});

  factory DisplayName.fromJson(Map<String, dynamic> json) {
    return DisplayName(
      text: json['text'] as String?,
      languageCode: json['languageCode'] as String?,
    );
  }
}