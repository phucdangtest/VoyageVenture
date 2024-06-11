import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:voyageventure/utils.dart';

class LatLngToAddressConverter extends StatefulWidget {
  const LatLngToAddressConverter({super.key});

  @override
  State<LatLngToAddressConverter> createState() =>
      _LatLngToAddressConverterState();
}

class _LatLngToAddressConverterState extends State<LatLngToAddressConverter> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _coordinatesController = TextEditingController();
  String _convertedAddress = 'None';
  String _convertedCoordinates = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Nhập địa chỉ'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  List<Location> locations = await locationFromAddress(
                      "Vietnam, HoChi Minh City, District 1, Nguyen Hue Street");

                  setState(() {
                    _convertedCoordinates =
                        'Latitude: ${locations[0].latitude}, Longitude: ${locations[0].longitude}';
                    logWithTag(_convertedCoordinates,
                        tag: 'LatLngToAddressConverter');
                  });
                } catch (e) {
                  print('Failed to convert address to coordinates: $e');
                }
              },
              child: Text('Chuyển đổi địa chỉ'),
            ),
            Text(_convertedCoordinates),
            TextField(
              controller: _coordinatesController,
              decoration: InputDecoration(
                  labelText: 'Nhập tọa độ (latitude,longitude)'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  List<String> coordinates =
                      _coordinatesController.text.split(',');
                  // List<Placemark> placemarks = await placemarkFromCoordinates(
                  //     double.parse(coordinates[0]),
                  //     double.parse(coordinates[1]));
                  List<Placemark> placeMarks = await placemarkFromCoordinates(9.3829827,105.7859591);
                  setState(() {
                    _convertedAddress =
                    '${placeMarks[0].name}, ${placeMarks[0].street}, ${placeMarks[0].subLocality}, ${placeMarks[0].locality}, ${placeMarks[0].administrativeArea}, ${placeMarks[0].country}, ${placeMarks[0].postalCode}';
                    logWithTag(_convertedAddress,
                        tag: 'LatLngToAddressConverter');
                  });
                } catch (e) {
                  print('Failed to convert coordinates to address: $e');
                }
              },
              child: Text('Chuyển đổi tọa độ'),
            ),
            Text(_convertedAddress),
          ],
        ),
      ),
    );
  }
}
