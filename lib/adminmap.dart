import 'dart:core';
import 'dart:ffi';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ipsmain/api/models/user-tracking-grpc.dart';
import 'package:ipsmain/api/user-tracking.dart';
import 'package:ipsmain/crewlist.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'navbar.dart' as CustomNavBar;
import 'dart:math';

class AdminMap extends StatefulWidget {
  @override
  _AdminMapState createState() => _AdminMapState();
}

class _AdminMapState extends State<AdminMap> {
  late latLng.LatLng _center;
  late double _zoom;
  late MapController _mapController;
  late List<Marker> markerList;
  late List<OnlineUser> userList;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Dropdown menu values
  String selectedBuilding = 'CMKL';
  int selectedFloor = 6;


  bool isOpen = false;

  @override
  void initState() {
    super.initState();
    // Initial center coordinates and zoom level
    const start_lat = 13.7279936;
    const start_lng = 100.7782921;
    const start_zoom = 21.5;
    markerList = [];
    userList = [];
    _center = latLng.LatLng(start_lat, start_lng);
    _mapController = MapController();
    _zoom = start_zoom;

    // Set initial values for text field controllers
    _latitudeController.text = _center.latitude.toString();
    _longitudeController.text = _center.longitude.toString();
    _zoomController.text = _zoom.toString();
    initScanUser();
    keepUpdateUserCoordinate();
  }

  Future<void> keepUpdateUserCoordinate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Timer.periodic(Duration(seconds: 4), (timer) {
      //getCoordinate();
      getOnlineUser(selectedBuilding, selectedFloor, prefs.getString('accessToken'), 13.72785451, 100.77848733).then((onlineUser) => setState(() {
        userList = onlineUser;
      }));
      searchUsers();
    });
  }

  void moveCenter() {
    _mapController.move(_center, _zoom);
  }

  void focusCenter() {
    double avgLat = 0;
    double avgLng = 0;
    for (var eachUser in userList) {
      avgLat += eachUser.latitude;
      avgLng += eachUser.longitude;
    }
    if (userList.isEmpty) {
      avgLat = avgLat / userList.length;
      avgLng = avgLng / userList.length;
      _mapController.move(latLng.LatLng(avgLat, avgLng), 21);
    } else {
      print("there's no user active in this floor");
    }
  }

  void genUserMarker(OnlineUser user) {
    markerList.add(
      Marker(
        point: latLng.LatLng(user.latitude, user.longitude),
        width: 50.0,
        height: 50.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: 25.0,
              color: Colors.white, // Set the icon color to white
            ),
            Text(
              user.displayName,
              style: TextStyle(
                color: Colors.white, // Set the text color to white
              ),
            ),
          ],
        ),
      ),
    );
  }

  void initScanUser() {}

  void searchUsers() {
    setState(() {
      markerList.clear(); // Clear existing markers
      for (var user in userList) {
        print(user.latitude);
        genUserMarker(user);
      }
    });
  }

  Widget get _appBar {
    return Opacity(
        opacity: 1,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xffffffff),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x50D5D8DC),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                height: 64,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.home_rounded,
                                  color:  Color(0xff68A8E9),),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton2<String>(
                                    isExpanded: true,
                                    value: selectedBuilding,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedBuilding = newValue!;
                                      });
                                    },
                                    buttonStyleData: const ButtonStyleData(
                                      width: 170,
                                      padding: EdgeInsets.only(left: 14, right: 14),
                                      elevation: 2,
                                    ),
                                    iconStyleData: const IconStyleData(
                                      icon: Icon(
                                        Icons.arrow_drop_down_rounded,
                                      ),
                                      iconSize: 30,
                                      iconEnabledColor: Color(0xff242527),
                                    ),
                                    dropdownStyleData: DropdownStyleData(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      offset: const Offset(-20, 0),
                                      scrollbarTheme: ScrollbarThemeData(
                                        radius: const Radius.circular(40),
                                        thickness: MaterialStateProperty.all(6),
                                        thumbVisibility: MaterialStateProperty.all(true),
                                      ),
                                    ),
                                    items: <String>[
                                      'CMKL',
                                      '12-Building',
                                    ].map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            DropdownButtonHideUnderline(
                                child: DropdownButton2<String>(
                                  isExpanded: true,
                                  value: selectedFloor.toString(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedFloor = int.parse(newValue!);
                                    });
                                  },
                                  buttonStyleData: const ButtonStyleData(
                                    width: 130,
                                    padding: EdgeInsets.only(left: 14, right: 14),
                                    elevation: 2,
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                    ),
                                    iconSize: 30,
                                    iconEnabledColor: Color(0xff242527),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    offset: const Offset(-10, 0),
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: const Radius.circular(40),
                                      thickness: MaterialStateProperty.all(6),
                                      thumbVisibility: MaterialStateProperty.all(true),
                                    ),
                                  ),
                                  items: <int>[
                                    6,
                                    7,
                                    8,
                                  ].map<DropdownMenuItem<String>>((int value) {
                                    return DropdownMenuItem<String>(
                                      value: value.toString(),
                                      child: Text(value.toString()),
                                    );
                                  }).toList(),
                                ))
                          ],
                        )
                      ),
                    ]))));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    center: _center,
                    zoom: _zoom,
                  ),
                  mapController: _mapController,
                  children: [
                    TileLayer(
                      urlTemplate:
                      selectedFloor == '6th Floor' ? 'https://api.mapbox.com/styles/v1/kl63011179/cltnawp1e01ll01pj0akv7ofx/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2w2MzAxMTE3OSIsImEiOiJjbHQwYmlwZzMweG0wMnFud3V6YzBnMzVxIn0.obh5q2t-Ppzi0VepoBICYg':
                      selectedFloor == '7th Floor' ? 'https://api.mapbox.com/styles/v1/kl63011179/cltnap3la00n501pka0jc9uji/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2w2MzAxMTE3OSIsImEiOiJjbHQwYmlwZzMweG0wMnFud3V6YzBnMzVxIn0.obh5q2t-Ppzi0VepoBICYg'
                    : '',

                      additionalOptions: {
                        'accessToken':
                            'sk.eyJ1Ijoia2w2MzAxMTE3OSIsImEiOiJjbHQxMmd6dTkxN2hhMmtseno0bm85c3MwIn0.IyAPKgQRGnXIixpbals4VQ',
                      },
                    ),
                    MarkerLayer(
                      markers: markerList,
                    )
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: _appBar,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xff68A8E9), //bg color
          onPressed: () {
    },

            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                customButton: const Icon(
                  Icons.more_vert,
                  size: 32,
                  color: Colors.white,
                ),
                dropdownStyleData: DropdownStyleData(
                  width: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xff68A8E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  offset: const Offset(-12, 210),
                ),
                items: const[
                  DropdownMenuItem(
                      value: 'searchUsers',
                      child: Icon(
                          color: Colors.white,
                        Icons.search,
                      )

                    ),
                  DropdownMenuItem(
                      value: 'focusCenter',
                      child: Icon(
                          Icons.location_searching,
                        color: Colors.white,
                      )
                  ),
                  DropdownMenuItem(
                      value: 'crewList',
                      child:  Icon(
                          Icons.people_alt_rounded,
                        color: Colors.white,
                        )

                  ),
                ],
                onChanged: (value) {
                  switch (value) {
                    case 'searchUsers':
                      searchUsers();
                      break;
                    case 'focusCenter':
                      focusCenter();
                      break;
                    case 'crewList':
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => CrewList(),
                          transitionDuration: Duration(seconds: 0),
                        ),
                      );
                      break;
                  }
                },

              )
      ),
          )],
      ),
      bottomNavigationBar: CustomNavBar.NavigationBar(
        currentIndex: 1,
      ),
    );
  }


  @override
  void dispose() {
    _compassSubscription?.cancel();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _zoomController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminMap(),
  ));
}
