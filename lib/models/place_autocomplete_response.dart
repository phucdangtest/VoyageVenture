import 'dart:convert';

import 'package:http/http.dart';
import 'package:voyageventure/models/place_autocomplete.dart';
import 'package:voyageventure/utils.dart';

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

  String getShortPlaces() {
    return suggestions?.map((suggestion) => suggestion.structuredFormat?.mainText ?? '').join('\n') ?? '';
  }

  @override
  String toString(){
    return 'PlaceAutocompleteResponse_ { suggestions:\n${getShortPlaces()} }';
  }
}