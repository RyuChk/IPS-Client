import 'package:flutter/material.dart';
import 'mapshow.dart';
import 'mymap.dart';
import 'adminmap.dart';
//import 'adminmap.dart'; // Import AdminMap page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/mymap', // Set initial route to MyMap
      routes: {
        '/mapshow': (context) => CustomMap(), // Define route for CustomMap
        '/mymap': (context) => MyMap(),
        '/adminmap': (context) => AdminMap(),
        // '/admin': (context) => AdminMap(), // Define route for AdminMap
      },
    );
  }
}
