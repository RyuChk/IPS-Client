import 'package:flutter/material.dart';
import 'mapshow.dart';
import 'mymap.dart';
import 'adminmap.dart';

class NavigationBar extends StatelessWidget {
  final int currentIndex;

  NavigationBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (int index) {
        // Handle navigation when a menu item is tapped
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => MyMap(),
                transitionDuration: Duration(seconds: 0),
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => AdminMap(),
                transitionDuration: Duration(seconds: 0),
              ),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => CustomMap(),
                transitionDuration: Duration(seconds: 0),
              ),
            );
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.map_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Overwatch',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mode_edit_rounded),
          label: 'Sandbox',
        ),
      ],
    );
  }
}
