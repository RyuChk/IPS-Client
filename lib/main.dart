import 'package:flutter/material.dart';
import 'mapshow.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/mapshow', // Set initial route to mapshow.dart
      routes: {
        '/mapshow': (context) => CustomMap(), // Define route for mapshow.dart
      },
    );
  }
}
