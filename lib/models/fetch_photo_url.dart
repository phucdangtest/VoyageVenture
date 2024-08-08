import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:voyageventure/utils.dart';
Future<List<String>> fetchPhotoUrls(String placeID, http.Client client, String key) async {
  final response = await client.get(Uri.parse('https://places.googleapis.com/v1/places/${placeID}?fields=photos&key=${key}'));
  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    List<String> photoUrls = [];
    if (jsonResponse['photos'] != null) {
      for (var photo in jsonResponse['photos']) {
        photoUrls.add(photo['name']);
      }
      logWithTag(photoUrls.toString(), tag: 'fetchPhotoUrls of $placeID');
      return photoUrls;

    }
    else {
      return photoUrls;
    }
    //logWithTag(photoUrls.toString(), tag: 'fetchPhotoUrls of $placeID');

  } else {
    throw Exception('Failed to load photos');
  }
}
