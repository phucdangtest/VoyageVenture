import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_places_flutter_api/google_places_flutter_api.dart';
import 'package:voyageventure/components/fonts.dart';
import 'package:voyageventure/components/location_list_tile.dart';
import 'package:voyageventure/components/mock_list.dart';
import 'package:voyageventure/components/network_utils.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/models/place_autocomplete_response.dart';
import 'package:voyageventure/models/place_search_response.dart';
import 'package:voyageventure/utils.dart';
import 'package:http/http.dart' as http;

import '../models/place_autocomplete.dart';
import '../models/place_search.dart';

class LocationSearchScreen_ extends StatefulWidget {
  ScrollController controller;

  LocationSearchScreen_({Key? key, required this.controller}) : super(key: key);

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: defaultPadding, right: defaultPadding, top: defaultPadding, bottom: 8.0),
          child: CupertinoSearchTextField(
            style: leagueSpartanNormal20,
            placeholder: "Tìm địa điểm",
            onChanged: (value) {
              logWithTab("Place auto complete: $value",
                  tag: "SearchLocationScreen");
              placeAutocomplete(value);
            },
            onSubmitted: (value) {
              logWithTab("Place search: $value", tag: "SearchLocationScreen");
              placeSearch(value);
            },
          ),
        ),
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(left: defaultPadding, right: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  logWithTab("Button clicked: ", tag: "SearchLocationScreen");
                  placeSearch("Nha tho");
                },
                icon: SvgPicture.asset(
                  "assets/icons/home_add.svg",
                  height: 16,
                ),
                label: Text("Thêm nhà", style: leagueSpartanNormal15),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor10LightTheme,
                  foregroundColor: textColorLightTheme,
                  elevation: 0,
                  fixedSize: const Size(double.infinity, 40),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                logWithTab("Button clicked: ", tag: "SearchLocationScreen");
                placeSearch("Nha tho");
              },
              icon: SvgPicture.asset(
                "assets/icons/location_add.svg",
                height: 16,
              ),
              label: Text("Thêm địa điểm", style: leagueSpartanNormal15),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor10LightTheme,
                foregroundColor: textColorLightTheme,
                elevation: 0,
                fixedSize: const Size(double.infinity, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ],
        ),

        placeFound
            ? ListView.builder(
                controller: widget.controller,
                shrinkWrap: true,
                itemCount: placeAutoList.length,
                itemBuilder: (context, index) {
                  return LocationListTile_(
                    press: () {
                      logWithTab(
                          "Location clicked: ${placeAutoList[index].toString()}",
                          tag: "SearchLocationScreen");
                    },
                    placeName:
                        placeAutoList[index].structuredFormat?.mainText?.text ??
                            "",
                    location: placeAutoList[index]
                            .structuredFormat
                            ?.secondaryText
                            ?.text ??
                        "",
                  );
                },
              )
            : const Center(child: Text('Không tìm thấy địa điểm')),
        //MockList_()
      ],
    );
  }
}
