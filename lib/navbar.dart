import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authenpage.dart';
import 'mymap.dart';
import 'adminmap.dart';
import 'settingpage.dart';
import 'package:http/http.dart' as http;

class NavigationBar extends StatelessWidget {

  final int currentIndex;
  final bool isAdmin;

  NavigationBar({required this.currentIndex, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: currentIndex,
        backgroundColor: Colors.white, // Set the background color to white
        selectedItemColor:
            const Color(0xff68A8E9), // Set the selected item color to black
        unselectedItemColor:
            const Color(0xff9C9C9C), // Set the unselected item color to black
        onTap: (int index) {
          // Handle navigation when a menu item is tapped
          switch (isAdmin) {
            case true:
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
                      pageBuilder: (_, __, ___) => SettingPage(),
                      transitionDuration: Duration(seconds: 0),
                    ),
                  );
                  break;
              }
              break;
            case false:
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
                      pageBuilder: (_, __, ___) => SettingPage(),
                      transitionDuration: Duration(seconds: 0),
                    ),
                  );
                  break;
              }
              break;
          }
        },
        items: (isAdmin
            ? [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.map_rounded,
                    size: 28,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.admin_panel_settings,
                    size: 28,
                  ),
                  label: 'Overwatch',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 28,
                  ),
                  label: 'Setting',
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.map_rounded,
                    size: 28,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 28,
                  ),
                  label: 'Setting',
                ),
              ]));
  }
}
