// test/utils_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/utils.dart';

void main() {
  group('LatLngToString Tests', () {
    test('Returns formatted string with cutoff', () {
      LatLng latLng = LatLng(10.123456789, 106.987654321);
      String result = LatLngToString(latLng, isCutoff: true);
      expect(result, '10.123457, 106.987654');
    });

    test('Returns full string without cutoff', () {
      LatLng latLng = LatLng(10.123456789, 106.987654321);
      String result = LatLngToString(latLng, isCutoff: false);
      expect(result, '10.123456789, 106.987654321');
    });
  });
}