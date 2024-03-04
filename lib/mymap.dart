import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:ipsmain/repository.dart';
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
  late WebSocket _socket;
  late double _direction; // Direction for the marker rotation

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    // Initial center coordinates and zoom level
    const start_lat = 13.72765;
    const start_lng = 100.772435;
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
    // Set initial values for text field controllers
    _latitudeController.text = _center.latitude.toString();
    _longitudeController.text = _center.longitude.toString();
    _zoomController.text = _zoom.toString();
    _initializeCompass();
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

  void _initializeWebSocket() async {
    try {
      // Replace 'ws://your_server_ip:port' with your WebSocket server URL
      _socket = await WebSocket.connect('ws://your_server_ip:port');
      print('WebSocket connected');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
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

  Future<void> collectPositionData() async {
    //final apiUrl = 'http://172.20.10.6:8080/api/v1/rssi/collectdata';
    final apiUrl = 'https://bff-api.cie-ips.com/api/v1/user/ws';
    //cie 10.0.9.6

    final jsonData = {
      'Signals': newAP,
    };
    List<String> deviceInfo = await getDeviceInfo();
    String deviceId = deviceInfo[0];
    String deviceModel = deviceInfo[1];

    final headers = {
      'X-Device-ID': deviceId,
      'X-Device-Model': deviceModel,
      'Content-Type': 'application/json',
    };
    print("body obj");
    print(jsonData);
    if (!isWiFiScanned) {
      print("not send data because scan not complete");

      isWiFiScanned = false;

      return;
    }

    _socket.add(jsonData);
    print('Data sent: $jsonData');

    //newAP = [];
  }

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

  Future<void> getCoordinate() async {
    print("Sending");
    await updateAP();
    await collectPositionData();
    newAP = [];
    accessPoints = [];
  }

  void keepUpdateCoordinate() {
    var dummyX = 0;
    var dummyY = 0;
    Timer.periodic(Duration(seconds: 2), (timer) {
      print("updating location");
      //getCoordinate();
      var newLocation = UserLocation(0, 0, 0, "x", "x");

      newLocation.fetchLocation(dummyX, dummyY);
      dummyX += 1;
      if (dummyX > 10) {
        dummyX = 0;
        dummyY -= 1;
      }

      moveUser(newLocation.latitude, newLocation.longitude);

      //change marker
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
    _mapController.move(latLng.LatLng(userLat, userLng), 21.5);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Map'),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Building name
                    Text(
                      'CMKL Building',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Floor name
                    Text(
                      '7th F',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Label
                    Text(
                      'Corridor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    markers: [
                      Marker(
                        point: _userCenter,
                        width: 50.0,
                        height: 50.0,
                        rotate: true, // Rotate the marker based on direction
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle:
                              -_direction, // Rotate the arrow based on compass heading
                          child: Icon(
                            Icons.arrow_circle_up_rounded,
                            size: 50.0,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                focusUser();
              },
              tooltip: 'Focus User',
              child: Icon(Icons.location_searching),
            ),
          ],
        ),
        bottomNavigationBar: CustomNavBar.NavigationBar(
          currentIndex:
              0, // Set the currentIndex according to your needs // Use the NavigationBar widget with the alias
        ));
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
