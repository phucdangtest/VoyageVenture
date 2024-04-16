import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_places_flutter_api/google_places_flutter_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyageventure/utils.dart';

class MySearchBar extends StatefulWidget {
  const MySearchBar({super.key});

  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> {
  final _controller = TextEditingController();
  late String API_KEY;
  late GoogleMapsPlaces _places;

  @override
  void initState() {
    super.initState();
    API_KEY = dotenv.env['MAPS_API_KEY1']!;
    _places = GoogleMapsPlaces(apiKey: API_KEY);
  }

  Future<void> _handleSearch() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey:  API_KEY,
      mode: Mode.fullscreen,
      language: "en",
      components: [Component(Component.country, "us")],
    );

    if (p != null && p.placeId != null) {
      PlacesDetailsResponse detail =
      await _places.getDetailsByPlaceId(p.placeId!);
      double lat = detail.result.geometry!.location.lat;
      double lng = detail.result.geometry!.location.lng;
      //showToast("Latitude: $lat, Longitude: $lng");
      print('$lat, $lng');
    }
    else {
      print('No place selected');
      //showToast("No place selected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Search',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: _handleSearch,
          ),
        ),
      ),
    );
  }
}
