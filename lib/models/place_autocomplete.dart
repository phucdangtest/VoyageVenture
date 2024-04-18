// class PlaceAutocomplete_ {
//   /// [description] contains the human-readable name for the returned result. For establishment results, this is usually
//   /// the business name.
//   final String? description;
//
//   /// [structuredFormatting] provides pre-formatted text that can be shown in your autocomplete results
//   final StructuredFormatting? structuredFormatting;
//
//   /// [placeId] is a textual identifier that uniquely identifies a place. To retrieve information about the place,
//   /// pass this identifier in the placeId field of a Places API request. For more information about place IDs.
//   final String? placeId;
//
//   /// [reference] contains reference.
//   final String? reference;
//
//   PlaceAutocomplete_({
//     this.description,
//     this.structuredFormatting,
//     this.placeId,
//     this.reference,
//   });
//
//   factory PlaceAutocomplete_.fromJson(Map<String, dynamic> json) {
//     return PlaceAutocomplete_(
//       description: json['description'] as String?,
//       placeId: json['place_id'] as String?,
//       reference: json['reference'] as String?,
//       structuredFormatting: json['structured_formatting'] != null
//           ? StructuredFormatting.fromJson(json['structured_formatting'])
//           : null,
//     );
//   }
// }
//
// class StructuredFormatting {
//   /// [mainText] contains the main text of a prediction, usually the name of the place.
//   final String? mainText;
//
//   /// [secondaryText] contains the secondary text of a prediction, usually the location of the place.
//   final String? secondaryText;
//
//   StructuredFormatting({this.mainText, this.secondaryText});
//
//   factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
//     return StructuredFormatting(
//       mainText: json['main_text'] as String?,
//       secondaryText: json['secondary_text'] as String?,
//     );
//   }
// }


import 'package:flutter_google_maps_webservices/places.dart';

class StructuredFormatting_ {
  final Text_? mainText;
  final Text_? secondaryText;

  StructuredFormatting_({this.mainText, this.secondaryText});

  factory StructuredFormatting_.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting_(
      mainText: json['mainText'] != null ? Text_.fromJson(json['mainText']) : null,
      secondaryText: json['secondaryText'] != null ? Text_.fromJson(json['secondaryText']) : null,
    );
  }
}

class PlaceAutocomplete_ {
  final String? place;
  final String? placeId;
  final Text_? text;
  final StructuredFormatting_? structuredFormat;
  final List<String>? types;

  PlaceAutocomplete_({
    this.place,
    this.placeId,
    this.text,
    this.structuredFormat,
    this.types,
  });

  factory PlaceAutocomplete_.fromJson(Map<String, dynamic> json) {
    return PlaceAutocomplete_(
      place: json['place'] as String?,
      placeId: json['placeId'] as String?,
      text: json['text'] != null ? Text_.fromJson(json['text']) : null,
      structuredFormat: json['structuredFormat'] != null
          ? StructuredFormatting_.fromJson(json['structuredFormat'])
          : null,
      types: json['types'] != null
          ? List<String>.from(json['types'])
          : null,
    );
  }
}

class Text_ {
  final String? text;
  final List<Match_>? matches;

  Text_({this.text, this.matches});

  factory Text_.fromJson(Map<String, dynamic> json) {
    return Text_(
      text: json['text'] as String?,
      matches: json['matches'] != null
          ? (json['matches'] as List)
          .map((item) => Match_.fromJson(item))
          .toList()
          : null,
    );
  }
}

class Match_ {
  final int? endOffset;

  Match_({this.endOffset});

  factory Match_.fromJson(Map<String, dynamic> json) {
    return Match_(
      endOffset: json['endOffset'] as int?,
    );
  }
}