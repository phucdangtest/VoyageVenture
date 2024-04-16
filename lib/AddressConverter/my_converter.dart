import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class LatLngToAddressConverter extends StatefulWidget {
  const LatLngToAddressConverter({super.key});

  @override
  State<LatLngToAddressConverter> createState() =>
      _LatLngToAddressConverterState();
}

class _LatLngToAddressConverterState extends State<LatLngToAddressConverter> {
  String place = "Null";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              // This makes the Container take up all available horizontal space
              child: FilledButton(
                onPressed: () async {
                  List<Location> locations = await locationFromAddress(
                      "Vietnam, HoChi Minh City, District 1, Nguyen Hue Street");


                  List<Placemark> placemarks =
                      await placemarkFromCoordinates(9.3829827,105.7859591);
                  setState(() {
                    place =
                        '${placemarks[0].name}, ${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].country}, ${placemarks[0].postalCode},'
                            ' " \n" , "Location", ${locations[0].latitude}, ${locations[0].longitude}';
                  });
                },
                child: const Text("Convert to Address"),
              ),
            ),
            Text("Address: $place"),
          ],
        ),
      ),
    );
  }
}
