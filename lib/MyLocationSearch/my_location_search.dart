import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:voyageventure/components/location_list_tile.dart';
import 'package:voyageventure/components/network_utils.dart';
import 'package:voyageventure/constants.dart';
import 'package:voyageventure/models/place_search_response.dart';
import 'package:voyageventure/utils.dart';
import 'package:http/http.dart' as http;

import '../models/place_search.dart';

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({Key? key}) : super(key: key);

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  List<placeSearch> placePredictions = [];

  void placeAutocompleteOld(String querry) async {
    print("Autocomplete: $querry");
    Uri uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': querry,
      'key': dotenv.env['MAPS_API_KEY1']!,
    });
    print("Querry: " + uri.toString());
    logWithTab("Querry: " + uri.toString(), tag: "SearchLocationScreen");
    String? response = await NetworkUtils.fetchUrl(uri);
    if (response != null) {
      placeSeachResponse result =
          placeSeachResponse.parseAutocompleteResult(response);
      if (result.places != null) {
        setState(() {
          placePredictions = result.places!;
        });
      }
    }
  }

  void placeAutocompleteNew(String query) async {
    print("Autocomplete: $query");
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
      logWithTab("Response: ${response.body}", tag: "SearchLocationScreen");
      placeSeachResponse result =
          placeSeachResponse.parseAutocompleteResult(response.body);
      if (result.places != null) {
        setState(() {
          placePredictions = result.places!;
        });
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: defaultPadding),
          child: CircleAvatar(
            backgroundColor: secondaryColor10LightTheme,
            child: SvgPicture.asset(
              "assets/icons/location.svg",
              height: 16,
              width: 16,
              color: secondaryColor40LightTheme,
            ),
          ),
        ),
        title: const Text(
          "Set Delivery Location",
          style: TextStyle(color: textColorLightTheme),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: secondaryColor10LightTheme,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.close, color: Colors.black),
            ),
          ),
          const SizedBox(width: defaultPadding)
        ],
      ),
      body: Column(
        children: [
          Form(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: TextFormField(
                onChanged: (value) {
                  logWithTab("Place: $value", tag: "SearchLocationScreen");
                  placeAutocompleteNew(value);
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
                placeAutocompleteNew("Nha tho");
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
          Expanded(
            child: ListView.builder(
              itemCount: placePredictions.length,
              itemBuilder: (context, index) {
                return LocationListTile(
                  press: () {},
                  location: placePredictions[index].displayName?.text ?? "",
                );
              },
            ),
          ),
          // LocationListTile(
          //   press: () {},
          //   location: "Banasree, Dhaka, Bangladesh",
          // ),
        ],
      ),
    );
  }
}
