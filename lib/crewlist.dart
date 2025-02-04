import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ipsmain/api/models/user-tracking-grpc.dart';
import 'package:ipsmain/api/user-tracking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminmap.dart';
import 'authenpage.dart';
import 'navbar.dart' as CustomNavBar;
import 'package:http/http.dart' as http;

class CrewList extends StatefulWidget {
  @override
  _CrewListState createState() => _CrewListState();
}

class _CrewListState extends State<CrewList> {
  late String? username;
  late String? accessToken;
  late List<OnlineUserDetail> userLists = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? idToken = prefs.getString('idToken');
    if (accessToken != null && idToken != null) {
      await _verifyToken(accessToken);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthenPage(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    }
  }

  Future<void> _verifyToken(String accessToken) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('https://authentik.cie-ips.com/application/o/userinfo/'),
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode != 200) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AuthenPage(),
            transitionDuration: Duration(seconds: 0),
          ),
        );
      }
    } catch (e) {
      print('Error verifying token: $e');
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthenPage(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    }
  }

  Future<void> keepUpdateUserCoordinate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Timer.periodic(Duration(seconds: 4), (timer) {
      //getAllOnlineUsers();
      getAllOnlineUsers(prefs.getString('accessToken')!)
          .then((onlineUser) => setState(() {
                userLists = onlineUser;
              }));
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xff68A8E9),
        title: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_rounded, color: Colors.white),
                SizedBox(
                  width: 8,
                ),
                const Text(
                  'Overview',
                  style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
              ],
            )),
      ),
      body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: userLists.length > 0
                  ? (Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // loop for list all crews here
                              // for ( var i in userLists )
                              for (var i = 0; i < 5; i++)
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x50D5D8DC),
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: Offset(0,
                                                3), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xff68A8E9),
                                            ),
                                            width: 44,
                                            height: 44,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'rr' ??
                                                      '', //Todo: display name
                                                  style: TextStyle(
                                                      color: Color(0xff242527),
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Inter')),
                                              Row(
                                                children: [
                                                  Text('location:',
                                                      style: TextStyle(
                                                          color:
                                                              Color(0xff242527),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: 'Inter')),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Text(
                                                      'qq' ??
                                                          '', //Todo: location label
                                                      style: TextStyle(
                                                          color:
                                                              Color(0xff242527),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: 'Inter')),
                                                ],
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                            ],
                          )
                        ]))
                  : Column(children: [
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: Text('none of online user now',
                            style: TextStyle(
                                color: Color(0xff242527),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter')),
                      ),
                    ]))),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => AdminMap(),
                  transitionDuration: Duration(seconds: 0),
                ),
              );
            },
            tooltip: 'Map',
            backgroundColor: const Color(0xff68A8E9), //bg color
            child: const Icon(
              Icons.map_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
