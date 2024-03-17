import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:ipsmain/api/models/map-grpc.dart';
import 'package:http/io_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ipsmain/api/repository.dart';
import 'package:ipsmain/api/map.dart' as mapHandler;
import 'package:ipsmain/api/user-manager.dart' as userManagerHandler;
import 'package:ipsmain/skeleton.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'authenpage.dart';
import 'package:intl/intl.dart';
import 'package:device_info/device_info.dart';

import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:wifi_hunter/wifi_hunter_result.dart';
import 'navbar.dart'
    as CustomNavBar; // Import the custom navbar.dart file with an alias

class MyMap extends StatefulWidget {
  @override
  _MyMapState createState() => _MyMapState();


}

class _MyMapState extends State<MyMap> {
  WiFiHunterResult wiFiHunterResult = WiFiHunterResult();
  bool isWiFiScanInProgress = false;
  bool isWiFiScanned = false;
  int xinterval = 1;
  int xtimer = 15;
  var scannedArray = [];
  List<Map<String, dynamic>> newAP = [];
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  bool shouldCheckCan = true;
  late latLng.LatLng _center;
  late latLng.LatLng _userCenter;
  late double mapLat;
  late double mapLng;
  late double userLat;
  late double userLng;
  late double _zoom;
  late MapController _mapController;
  //late WebSocket _socket;
  late double _direction; // Direction for the marker rotation
  late Map<String, BuildingInfo> allBuilding;
  late BuildingInfo currentBuildingInfo;
  late String currentBuilding;
  late FloorDetail currentFloorInfo;
  late double zLevel = -999;
  late String verifiedToken;
  String buildingText = '';
  String floorText = '';
  String labelText = '';
  late List<Marker> pinList = [];
  late int mapInitialized = 0;
  late bool isBuildingValid = false;
  late bool isLoading = true;
  late String loadingText = 'Locating...';
  late bool isAdmin = false;
  late bool isCheckingRole = true;

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    // Initial center coordinates and zoom level
    const start_lat = 13.7279936;
    const start_lng = 100.7782921;
    const start_zoom = 21.5;
    _center = latLng.LatLng(start_lat, start_lng);
    _userCenter = latLng.LatLng(start_lat, start_lng);
    _mapController = MapController();
    mapLat = start_lat;
    mapLng = start_lng;
    userLat = start_lat;
    userLng = start_lng;
    _zoom = start_zoom;
    _direction = 0;
    allBuilding = Map();
    currentBuildingInfo = BuildingInfo('', '', 0.0, 0.0, []);
    verifiedToken = '';

    buildingText = "";
    floorText = "";
    labelText = "";
    // Set initial values for text field controllers
    _latitudeController.text = _center.latitude.toString();
    _longitudeController.text = _center.longitude.toString();
    _zoomController.text = _zoom.toString();
    _initializeCompass();
    //initializeMapInfo();
    keepUpdateCoordinate();
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

  // void _initializeWebSocket() async {
  //   try {
  //     // Replace 'ws://your_server_ip:port' with your WebSocket server URL
  //     _socket = await WebSocket.connect('ws://your_server_ip:port');
  //     print('WebSocket connected');
  //   } catch (e) {
  //     print('Error connecting to WebSocket: $e');
  //   }
  // }

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
        verifiedToken = accessToken;
        //check user's role
        Map<String, dynamic> data = json.decode(response.body);
        dynamic groups = data['groups'];
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
    finally {
      setState(() {
        isCheckingRole = false; // Move this line inside setState
      });
    }
  }

  Future<List<String>> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo? androidInfo; // Use nullable type

    try {
      androidInfo = await deviceInfo.androidInfo;
    } catch (e) {
      print('Error getting Android device info: $e');
    }

    final deviceId = androidInfo?.androidId ?? 'UNKNOWN';
    final deviceModel = androidInfo?.model ?? 'UNKNOWN';

    return [deviceId, deviceModel];
  }

  // Future<void> collectPositionData() async {
  //   //final apiUrl = 'http://172.20.10.6:8080/api/v1/rssi/collectdata';
  //   final apiUrl = 'https://bff-api.cie-ips.com/api/v1/user/ws';
  //   //cie 10.0.9.6

  //   final jsonData = {
  //     'Signals': newAP,
  //   };
  //   List<String> deviceInfo = await getDeviceInfo();
  //   String deviceId = deviceInfo[0];
  //   String deviceModel = deviceInfo[1];

  //   final headers = {
  //     'X-Device-ID': deviceId,
  //     'X-Device-Model': deviceModel,
  //     'Content-Type': 'application/json',
  //   };
  //   print("body obj");
  //   print(jsonData);
  //   if (!isWiFiScanned) {
  //     print("not send data because scan not complete");

  //     isWiFiScanned = false;

  //     return;
  //   }

  //   // _socket.add(jsonData);
  //   print('Data sent: $jsonData');

  //   //newAP = [];
  // }

  Future<void> huntWiFis() async {
    try {
      // Check if WiFi scan is already in progress
      if (isWiFiScanInProgress) {
        print("WiFi scan is already in progress. Skipping...");
        //toastWithVibrate("WiFi scan is already in progress. Skipping...");
        return;
      }

      // Set the WiFi scan flag to indicate that a scan is in progress
      isWiFiScanInProgress = true;

      print("Start hunting...");

      // Set a timeout for the WiFi scan operation (e.g., 10 seconds)
      if (xinterval <= 1) {
        xinterval = 3;
      }
      final timeoutDuration = Duration(seconds: xinterval);

      // Start the WiFi scan
      final wifiScanFuture =
          WiFiHunter.huntWiFiNetworksWithTimeout(xinterval + 1);

      // Create a delayed Future to handle the timeout
      final timeoutFuture = Future.delayed(timeoutDuration, () {
        // Set the WiFi scan flag to indicate that the scan has timed out
        isWiFiScanInProgress = false;
        if (!isWiFiScanned) {
          // scan time out
        }

        throw TimeoutException('WiFi scan timed out');
      });

      // Wait for either the WiFi scan to complete or the timeout to occur
      await Future.any([wifiScanFuture, timeoutFuture]).then((result) {
        // Handle the result (it could be either WiFi scan result or TimeoutException)
        if (result is WiFiHunterResult) {
          wiFiHunterResult = result;
          print("scannedArray: $scannedArray");
          //showToast("WiFi scan completed");
          isWiFiScanned = true;
          if (scannedArray.isNotEmpty) {
            scannedArray[scannedArray.length - 1] = true;
          }

          print("Done hunting!");
        }
      }).catchError((error) {
        // Handle other errors during WiFi scan
        if (error is TimeoutException) {
          // Ignore the timeout error here since it has been handled above
        } else {
          // Handle other errors
          //toastWithVibrate("WiFi scan encountered an error: $error");
          print("WiFi scan error: $error");
        }
      }).whenComplete(() {
        // Set the WiFi scan flag to indicate that the scan is no longer in progress
        isWiFiScanInProgress = false;
      });

      //toastWithVibrate("DONE HUNTING");
      print("Done hunting 2");
    } catch (exception) {
      // Handle unexpected exceptions
      //toastWithVibrate("An unexpected error occurred: $exception");
      print("Unexpected error during WiFi scan: $exception");
    }
  }

  Future<bool> _wifiCanGetScannedResults() async {
    if (shouldCheckCan) {
      final can = await WiFiScan.instance.canGetScannedResults();
      if (can != CanGetScannedResults.yes) {
        //log("Cannot get scanned results: $can");
        accessPoints = <WiFiAccessPoint>[];
        return false;
      }
    }
    return true;
  }

  Future<bool> _wifiGetResultsInJsonForm() async {
    if (await _wifiCanGetScannedResults()) {
      final results = await WiFiScan.instance.getScannedResults();
      accessPoints = results;
      return true;
    } else {
      accessPoints = <WiFiAccessPoint>[];
      return false;
    }
  }

  String formatNewDate(DateTime dateTime) {
    // Format the DateTime using the desired format
    String formattedDate = DateFormat("yyyy-MM-ddTHH:mm:ss").format(dateTime);

    // Get the timezone offset
    String timezoneOffset = getTimezoneOffset(dateTime);

    // Combine the formatted date and timezone offset
    return '$formattedDate$timezoneOffset';
  }

  String getTimezoneOffset(DateTime dateTime) {
    // Get the timezone offset in minutes
    int offsetMinutes = dateTime.timeZoneOffset.inMinutes;

    // Calculate the offset in hours and minutes
    int hours = offsetMinutes ~/ 60;
    int minutes = offsetMinutes % 60;

    // Format the offset as "+HH:mm" or "-HH:mm"
    String formattedOffset =
        '${hours.abs().toString().padLeft(2, '0')}:${minutes.abs().toString().padLeft(2, '0')}';

    // Determine the sign of the offset
    String sign = offsetMinutes >= 0 ? '+' : '-';

    return '$sign$formattedOffset';
  }

  void addNewStrength(String ssid, String bssid, double level) {
    print("current AP: ");
    //print(newAP);
    for (int i = 0; i < newAP.length; i++) {
      if (newAP[i]['mac_address'] == bssid) {
        newAP[i]['Strength'].add(level);
        newAP[i]['created_at'].add(formatNewDate(DateTime.now()));
        return;
      }
    }

    // If BSSID not found, add a new entry
    newAP.add({
      'Ssid': ssid,
      'mac_address': bssid,
      'Strength': [level.toDouble()],
      'created_at': [formatNewDate(DateTime.now())]
    });
  }

  Future updateAP() async {
    print("start hunting");
    await huntWiFis();
    print("hunted");
    if (await _wifiGetResultsInJsonForm()) {
      print("accespoints: ");
      //print(accessPoints);
      for (int i = 0; i < accessPoints.length; i++) {
        addNewStrength(accessPoints[i].ssid, accessPoints[i].bssid,
            accessPoints[i].level.toDouble());
      }
      print("updated new ap info");
    }
  }

  void makeEmptyLocationText() {
    setState(() {
      buildingText = "";
      floorText = "";
      labelText = "";
    });
  }

  void addUserToMap() {
    pinList.add(Marker(
      point: _userCenter,
      width: 50.0,
      height: 100.0,
      rotate: true, // Rotate the marker based on direction
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: -_direction, // Rotate the arrow based on compass heading
        child: const Icon(
          Icons.arrow_circle_up_rounded,
          size: 50.0,
          color: Color(0xff68A8E9),
        ),
      ),
    ));
  }

  Future initializeMapInfo() async {
    print("init map info");
    mapInitialized = 1;
    currentBuilding = getCurrentBuilding();
    Future<Map<String, BuildingInfo>> buildingListFuture =
        mapHandler.getBuildingList(verifiedToken);
    allBuilding = await buildingListFuture;
    print('allBuilding: $allBuilding');
    if (!allBuilding.containsKey(currentBuilding)) {
      print("init map no key emptying:");
      makeEmptyLocationText();
      setState(() {
        isLoading = true;
        loadingText = 'Non-Service Buidling...';
      });
      //todo show err "Not in any service building" and
      //use fake default val
      return;
    }
    isBuildingValid = true;
    print("init first buildinginfo");
    Future<BuildingInfo> buildingInfoFuture =
        mapHandler.getBuildingInfo(currentBuilding, verifiedToken);
    currentBuildingInfo = await buildingInfoFuture;
    print("current INIT B");
    print(currentBuildingInfo.name);

    userLat = currentBuildingInfo.originLat;
    userLng = currentBuildingInfo.originLong;
    moveUser(userLat, userLng);
    focusUser();

    setState(() {
      buildingText = '${currentBuildingInfo.name} B.';
    });
    mapInitialized = 2;
  }

  void setNewBuildingInfo(String currentBuilding) async {
    //todo show changing to new building
    Future<BuildingInfo> buildingInfoFuture =
        mapHandler.getBuildingInfo(currentBuilding, verifiedToken);
    currentBuildingInfo = await buildingInfoFuture;

    print("current SET B");
    print(currentBuildingInfo.name);

    userLat = currentBuildingInfo.originLat;
    userLng = currentBuildingInfo.originLong;
    moveUser(userLat, userLng);
    focusUser();

    setState(() {
      buildingText = '${currentBuildingInfo.name} B.';
    });
  }

  void addRoomPin(String room, double lat, double lng) {
    pinList.add(
      Marker(
          width: 100.0,
          height: 100,
        alignment: Alignment.center,
        point: latLng.LatLng(lat, lng),
        child: SizedBox(
          width: 100.0,
          height: 100,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_pin,
              size: 30.0,
              color: Colors.white, // Set the icon color to white
            ),
            Text(
              room,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter'),
            ),
          ],
        ),)
      ),
    );
  }

  void changeFloorMapAppearance() {
    //todo change map appearance for this floor
    pinList.clear();

    for (var room in currentFloorInfo.room) {
      addRoomPin(room.name, room.latitude, room.longitude);
    }
    addUserToMap();
  }

  void setNewFloorInfo(double currentFloor) async {
    print("getting floor from server");
    Future<FloorDetail> floorInfoFuture = mapHandler.getFloorDetailFromServer(
        currentBuildingInfo.name, currentFloor, verifiedToken);
    currentFloorInfo = await floorInfoFuture;
    print("new floor setter: ");
    print(currentFloorInfo.info.symbol);
    setState(() {
      floorText = '${currentFloorInfo.info.symbol} F.';
    });
    changeFloorMapAppearance();
  }

  String getCurrentBuilding() {
    //dummy
    return "CMKL";
  }

  void keepUpdateCoordinate() {
    Timer.periodic(Duration(seconds: 3), (timer) async {
      print("updating location");
      if (verifiedToken == '') {
        print("still no valid token");
        return;
      }
      if (mapInitialized == 0) {
        await initializeMapInfo();
      } else if (mapInitialized == 1) {
        return;
      }
      print("allBuilding print");
      print(allBuilding);

      print('current: $currentBuilding');

      var newCurrentBuilding = getCurrentBuilding();
      print('newcurrent: $newCurrentBuilding');
      if (currentBuilding != newCurrentBuilding) {
        print('changing building');
        currentBuilding = newCurrentBuilding;
        if (!allBuilding.containsKey(currentBuilding)) {
          print('not found in service building');
          isBuildingValid = false;
        } else {
          isBuildingValid = true;
          setNewBuildingInfo(currentBuilding);
        }
      }
      if (!isBuildingValid) {
        makeEmptyLocationText();
        print("emptying text: invalid building");
        setState(() {
          isLoading = true;
          loadingText = 'Non-Service Buidling...';
        });
        //todo skip below
        return;
      }
      await updateAP();
      print("updated AP");

      var data = {'Signals': newAP, 'building': currentBuildingInfo.name};
      newAP = [];
      accessPoints = [];

      if (!isWiFiScanned) {
        //todo skip below
        print("wifi not scanned");
        return;
      }

      // var newLocation = UserLocation(0, 0, 0, "x", "x");
      // newLocation.fetchLocation(0, 0, data);
      print("updating newLocation");
      var newLocationFuture =
          userManagerHandler.getUserLocation(data, verifiedToken);
      var newLocation = await newLocationFuture;
      print('newLocation: ');
      print(newLocation.label);
      print("current floor: $zLevel");
      print("newcurrent floor: ");
      print(newLocation.floor);

      if (newLocation.floor != zLevel) {
        print("setting new floor");
        zLevel = newLocation.floor;
        setNewFloorInfo(zLevel);
      }

      newLocation.originLat = currentBuildingInfo.originLat;
      newLocation.originLong = currentBuildingInfo.originLong;

      userLat = newLocation.latitude;
      userLng = newLocation.longitude;
      print("tele user to: ");
      print(userLat);
      print(userLng);
      moveUser(userLat, userLng);

      if (newLocation.label == labelText) {
        return;
      }

      setState(() {
        labelText = newLocation.label;
      });

      if (isLoading) {
        setState(() {
          isLoading = false;
          loadingText = '';
        });
      }
    });
  }

  void _initializeCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _direction = event.heading ?? 0.0;
        });
      }
    });
  }

  void moveCenter() {
    _mapController.move(latLng.LatLng(mapLat, mapLng), _zoom);
    print("current direction: $_direction");
  }

  void moveUser(newLat, newLng) {
    setState(() {
      userLat = newLat;
      userLng = newLng;
      _userCenter = latLng.LatLng(userLat, userLng);
    });
  }

  void focusUser() {
    mapLat = userLat;
    mapLng = userLng;
    _mapController.move(latLng.LatLng(mapLat, mapLng), 21.5);
    _mapController.rotate(0);
  }

  void moveToLocation(double lat, double lon, double zoom) {
    setState(() {
      _center = latLng.LatLng(lat, lon);
      _zoom = zoom;
      _latitudeController.text = lat.toString();
      _longitudeController.text = lon.toString();
      _zoomController.text = zoom.toString();
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
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Building name
                            Text(
                              buildingText,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color(0xff242527),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Floor name
                            Text(
                              floorText,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color(0xff242527),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Label
                            Text(
                              labelText,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color(0xff242527),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]))));
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingRole){
      return Navigator(
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(builder: (context) => SkeletonPage());
        },
      );
    } else {
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
                          'https://api.mapbox.com/styles/v1/kl63011179/clt162br900h501me9qyfdcg7/tiles/{z}/{x}/{y}?access_token=sk.eyJ1Ijoia2w2MzAxMTE3OSIsImEiOiJjbHQxMmd6dTkxN2hhMmtseno0bm85c3MwIn0.IyAPKgQRGnXIixpbals4VQ',
                          additionalOptions: {
                            'accessToken':
                            'sk.eyJ1Ijoia2w2MzAxMTE3OSIsImEiOiJjbHQxMmd6dTkxN2hhMmtseno0bm85c3MwIn0.IyAPKgQRGnXIixpbals4VQ',
                          },
                        ),
                        MarkerLayer(
                          markers: pinList,
                        )
                      ],
                    ),
                  ),

                ],
              ),
              if (isLoading)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xffffffff),
                          backgroundColor: Color(0xff68A8E9),
                        ),// Loading indicator
                        SizedBox(
                            height:
                            10), // Spacer between indicator and text
                        Text(
                          loadingText, // Text indicating loading status
                          style: TextStyle(color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 45,
                left: 0,
                right: 0,
                child: _appBar,
              ),
            ],
          ),
          floatingActionButton:
              // for admin only

              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton(
                  onPressed: () {
                    focusUser();
                  },
                  tooltip: 'Focus Center',
                  backgroundColor: const Color(0xff68A8E9), //bg color
                  child: const Icon(
                    Icons.location_searching,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              )

          ,
          bottomNavigationBar: CustomNavBar.NavigationBar(
            currentIndex:
            0, // Set the currentIndex according to your needs // Use the NavigationBar widget with the alias
              isAdmin: isAdmin
          ));
    }

  }

  @override
  void dispose() {
    // Dispose text field controllers
    _compassSubscription?.cancel();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _zoomController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: MyMap(),
  ));
}
