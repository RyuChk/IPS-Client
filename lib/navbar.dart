import 'package:flutter/material.dart';
import 'mapshow.dart';
import 'mymap.dart';
import 'adminmap.dart';
import 'settingpage.dart';

class NavigationBar extends StatelessWidget {
  final int currentIndex;

  NavigationBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return  BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: currentIndex,
        backgroundColor: Colors.white, // Set the background color to white
        selectedItemColor: const Color(0xff68A8E9), // Set the selected item color to black
        unselectedItemColor: const Color(0xff9C9C9C), // Set the unselected item color to black
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
            case 3:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => SettingPage(),
                  transitionDuration: Duration(seconds: 0),
                ),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded, size: 28,),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings,  size: 28,),
            label: 'Overwatch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mode_edit_rounded,  size: 28,),
            label: 'Sandbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz,  size: 28,),
            label: 'Setting',
          ),
        ],

    );
  }
}
