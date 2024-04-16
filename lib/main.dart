import 'package:flutter/material.dart';
import 'package:voyageventure/AddressConverter/my_converter.dart';
import 'package:voyageventure/MyHomeScreen/my_home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyageventure/MyLocationSearch/my_location_search.dart';

void main() async {
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SearchLocationScreen(),
    );
  }
}
