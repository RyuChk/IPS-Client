import 'package:flutter/material.dart';
import 'mapshow.dart';
import 'mymap.dart';
import 'adminmap.dart';
import 'authenpage.dart';
import 'settingpage.dart';
//import 'adminmap.dart'; // Import AdminMap page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      initialRoute: '/authenpage', // Set initial route to MyMap
      routes: {
        '/mapshow': (context) => CustomMap(), // Define route for CustomMap
        '/mymap': (context) => MyMap(),
        '/adminmap': (context) => AdminMap(),
        '/settingpage': (context) => SettingPage(),
        '/authenpage': (context) => AuthenPage(),
        // '/admin': (context) => AdminMap(), // Define route for AdminMap
      },
    );
  }
}
