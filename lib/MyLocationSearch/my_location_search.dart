import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_places_flutter_api/google_places_flutter_api.dart';
import 'package:voyageventure/components/location_list_tile.dart';
import 'package:voyageventure/components/network_utils.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/models/place_autocomplete_response.dart';
import 'package:voyageventure/models/place_search_response.dart';
import 'package:voyageventure/utils.dart';
import 'package:http/http.dart' as http;

import '../models/place_autocomplete.dart';
import '../models/place_search.dart';

class LocationSearchScreen_ extends StatefulWidget {
  const LocationSearchScreen_({super.key});

  @override
  State<LocationSearchScreen_> createState() => _LocationSearchScreen_State();
}

class _LocationSearchScreen_State extends State<LocationSearchScreen_> {
  List<PlaceAutocomplete_> placeAutoList = [];
  List<PlaceSearch_> placeSearchList = [];
  bool placeFound = true;

  void placeAutocomplete(String query) async {
    print("Autocomplete: $query");
    var url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
    var headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': dotenv.env['MAPS_API_KEY1']!,
    };
    var body = jsonEncode({
      'input': query,
      'locationBias': {
        'circle': {
          'center': {'latitude': 12.5199614, 'longitude': 107.5400949},
          'radius': 500.0
        }
      }
    });
    var response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      PlaceAutocompleteResponse_ result =
          PlaceAutocompleteResponse_.parseAutocompleteResult(response.body);
      if (result.suggestions != null) {
        setState(() {
          placeAutoList = result.suggestions!;
          logWithTab("Autocomplete: ${result.toString()}",
              tag: "SearchLocationScreen");
          placeFound = true;
        });
      } else {
        logWithTab("No predictions found", tag: "SearchLocationScreen");
        placeFound = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      logWithTab("Request failed with status: ${response.statusCode}.",
          tag: "SearchLocationScreen");
    }
  }

  void placeSearch(String query) async {
    print("Search: $query");
    var url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    var headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': dotenv.env['MAPS_API_KEY1']!,
      'X-Goog-FieldMask':
          'places.displayName,places.formattedAddress,places.location,places.id',
    };
    var body = jsonEncode({
      'textQuery': query,
    });
    var response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      PlaceSearchResponse_ result =
          PlaceSearchResponse_.parsePlaceSearchResult(response.body);
      if (result.places != null) {
        setState(() {
          placeSearchList = result.places!;
          logWithTab("Search: ${result.toString()}",
              tag: "SearchLocationScreen");
          placeFound = true;
        });
      } else {
        logWithTab("No places found", tag: "SearchLocationScreen");
        placeFound = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      logWithTab("Request failed with status: ${response.statusCode}.",
          tag: "SearchLocationScreen");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Form(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: TextFormField(
                onChanged: (value) {
                  logWithTab("Place: $value", tag: "SearchLocationScreen");
                  placeAutocomplete(value);
                  //placeSearch(value);
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: "Search your location",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SvgPicture.asset(
                      "assets/icons/location_pin.svg",
                      color: secondaryColor40LightTheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(
            height: 4,
            thickness: 4,
            color: secondaryColor5LightTheme,
          ),
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: ElevatedButton.icon(
              onPressed: () {
                logWithTab("Button clicked: ", tag: "SearchLocationScreen");
                //placeSearch("Nha tho");
                placeSearch("Nha tho");
              },
              icon: SvgPicture.asset(
                "assets/icons/location.svg",
                height: 16,
              ),
              label: const Text("Use my Current Location"),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor10LightTheme,
                foregroundColor: textColorLightTheme,
                elevation: 0,
                fixedSize: const Size(double.infinity, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          const Divider(
            height: 4,
            thickness: 4,
            color: secondaryColor5LightTheme,
          ),
          placeFound
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: placeAutoList.length,
                  itemBuilder: (context, index) {
                    return LocationListTile_(
                      press: () {
                        logWithTab(
                            "Location clicked: ${placeSearchList[index].toString()}",
                            tag: "SearchLocationScreen");
                      },
                      placeName: placeAutoList[index]
                              .structuredFormat
                              ?.mainText
                              ?.text ??
                          "",
                      location: placeAutoList[index]
                              .structuredFormat
                              ?.secondaryText
                              ?.text ??
                          "",
                    );
                  },
                )
              : const Center(child: Text('No place found')),
          // LocationListTile(
          //   press: () {},
          //   location: "Banasree, Dhaka, Bangladesh",
          // ),
        ],
    );
  }
}
