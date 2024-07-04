import 'package:flutter/material.dart';
import 'package:voyageventure/AddressConverter/my_converter.dart';
import 'package:voyageventure/MyHomeScreen/my_home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyageventure/MyLocationSearch/my_location_search.dart';
import 'package:firebase_core/firebase_core.dart';
import 'components/route_planning_list.dart';
import 'firebase_options.dart';
import 'location_sharing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo rằng các binding của widget đã được khởi tạo
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 68,190,195) ),
        useMaterial3: true,
      ),
      home: LocationSharing(),


    );
  }
}
