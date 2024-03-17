import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'authenpage.dart';
import 'mymap.dart';


class SkeletonPage extends StatefulWidget {

  @override
  _SkeletonPageState createState() => _SkeletonPageState();
}

class _SkeletonPageState extends State<SkeletonPage> {

  // late final Future<Map<String, dynamic>> _userRole;
  late bool isAdmin = false;
  late bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the widget initializes
  }

  // Function to check login status
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? idToken = prefs.getString('idToken');
    if (accessToken != null && idToken != null) {
      // Token exists, proceed to verify the token
      await _verifyToken(accessToken);
    } else {
      // If tokens are not available, navigate back to the authentication page
      print("token failed 1");
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthenPage(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    }
  }
  // Function to verify the token by fetching user info
  Future<void> _verifyToken(String accessToken) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('https://authentik.cie-ips.com/application/o/userinfo/'),
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
      );
      print("respy");
      print(response);
      if (response.statusCode != 200) {
        // Token is not valid, navigate back to the authentication page
        print("token failed 2");
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AuthenPage(),
            transitionDuration: Duration(seconds: 0),
          ),
        );
      } else {
        //verified
        //check user's role
        Map<String, dynamic> data = json.decode(response.body);
        dynamic groups = data['groups'];
        // _userRole = Future.value(data);
        // print('_userRole: $_userRole');
        if (groups is List<dynamic>) {
          isAdmin = groups.contains("authentik Admins");

        }
      }
    } catch (e) {
      print('Error verifying token: $e');
      // Navigate back to the authentication page in case of any errors
      print("token failed 3");
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthenPage(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
          body: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Center(
                    child: Container(
                        alignment: Alignment.center,
                        child: Image.asset(
                          "lib/icons/indoor.png",
                          height: 50,
                          width: 50,
                        )),
                  )),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Text(
                      'IPS Application',
                      style: TextStyle(
                          color: Color(0xff242527),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter'),
                    ),)
                ]
            ),
          )
      );
  }
}