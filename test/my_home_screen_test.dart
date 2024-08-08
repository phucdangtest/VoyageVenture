import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voyageventure/MyHomeScreen/my_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyageventure/models/fetch_photo_url.dart';
import 'package:voyageventure/models/map_style.dart';
import 'package:voyageventure/models/place_search.dart';
import 'package:voyageventure/models/route_calculate.dart';
import 'package:voyageventure/utils.dart';


@GenerateMocks([GoogleMapController])
import 'my_home_screen_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  group('_MyHomeScreenState', () {
    var state;
    late MockGoogleMapController mockGoogleMapController;

    setUp(() {
      state =  MyHomeScreen().createState();
      state.initState();
      mockGoogleMapController = MockGoogleMapController();
      state._mapsController.complete(mockGoogleMapController);
    });

    // test('animateToPosition should animate camera to the given position', () async {
    //   LatLng position = LatLng(10.0, 10.0);
    //   await state.animateToPosition(position, zoom: 15.0);
    //   verify(mockGoogleMapController.animateCamera(any)).called(1);
    // });
    //
    // test('animateToPositionNoZoom should animate camera to the given position without changing zoom', () async {
    //   LatLng position = LatLng(10.0, 10.0);
    //   when(mockGoogleMapController.getZoomLevel()).thenAnswer((_) async => 10.0);
    //   await state.animateToPositionNoZoom(position);
    //   verify(mockGoogleMapController.animateCamera(any)).called(1);
    // });

    // test('changeState should update the state', () {
    //   state.changeState("Search");
    //   expect(state.state, state.stateMap["Search"]);
    // });

    // test('changeDestinationLocationLatLgn should update destination location', () {
    //   LatLng position = LatLng(10.0, 10.0);
    //   state.mapData.changeDestinationLocationLatLgn(position);
    //   expect(state.mapData.destinationLocationLatLgn, position);
    // });

    // Add more tests for other methods as needed
  });
}