import 'dart:convert';

import 'package:voyageventure/models/place_autocomplete.dart';

class PlaceAutocompleteResponse_ {
  final List<PlaceAutocomplete_>? suggestions;

  PlaceAutocompleteResponse_({this.suggestions});

  factory PlaceAutocompleteResponse_.fromJson(Map<String, dynamic> json) {
    return PlaceAutocompleteResponse_(
      suggestions: json['suggestions'] != null
          ? (json['suggestions'] as List)
          .map((item) => PlaceAutocomplete_.fromJson(item['placePrediction']))
          .toList()
          : null,
    );
  }

  static PlaceAutocompleteResponse_ parseAutocompleteResult(
      String responseBody) {
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return PlaceAutocompleteResponse_.fromJson(parsed);
  }
}