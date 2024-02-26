import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'navbar.dart' as CustomNavBar;

class AdminMap extends StatefulWidget {
  @override
  _AdminMapState createState() => _AdminMapState();
}

class _AdminMapState extends State<AdminMap> {
  late latLng.LatLng _center;
  late double _zoom;
  late MapController _mapController;
  late List<Marker> markerList;
  late List<List> userList;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Dropdown menu values
  String selectedBuilding = 'E12 Building';
  String selectedFloor = '7th Floor';

  @override
  void initState() {
    super.initState();
    // Initial center coordinates and zoom level
    const start_lat = 13.72765;
    const start_lng = 100.772435;
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
  }

  void moveCenter() {
    _mapController.move(_center, _zoom);
  }

  void focusCenter() {
    double avgLat = 0;
    double avgLng = 0;
    for (var eachUser in userList) {
      avgLat += eachUser[1];
      avgLng += eachUser[2];
    }
    if (userList.isNotEmpty) {
      avgLat = avgLat / userList.length;
      avgLng = avgLng / userList.length;
      _mapController.move(latLng.LatLng(avgLat, avgLng), 21);
    } else {
      print("there's no user active in this floor");
    }
  }

  void genUserMarker(String user, double lat, double lng) {
    markerList.add(
      Marker(
        point: latLng.LatLng(lat, lng),
        width: 50.0,
        height: 50.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: 50.0,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            Text(user), // Add a label with the user name
          ],
        ),
      ),
    );
  }

  void searchUsers() {
    // Fetch users based on selected building and floor
    // Populate userList with fetched user data
    // Example:
    // userList = [
    //   ['John', 13.72765, 100.772435],
    //   ['Jane', 13.72770, 100.772490],
    //   ['Doe', 13.72780, 100.772400],
    // ];
    // Then generate markers for each user
    setState(() {
      markerList.clear(); // Clear existing markers
      for (var user in userList) {
        genUserMarker(user[0], user[1], user[2]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Overwatch'),
        actions: [
          // Dropdown for building selection
          DropdownButton<String>(
            value: selectedBuilding,
            onChanged: (String? newValue) {
              setState(() {
                selectedBuilding = newValue!;
              });
            },
            items: <String>['E12 Building', 'CMKL Building', 'HM Building']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          // Dropdown for floor selection
          DropdownButton<String>(
            value: selectedFloor,
            onChanged: (String? newValue) {
              setState(() {
                selectedFloor = newValue!;
              });
            },
            items: <String>['7th Floor', '8th Floor', '9th Floor']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
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
                  markers: markerList,
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: searchUsers,
            tooltip: 'Search',
            child: Icon(Icons.search),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: focusCenter,
            tooltip: 'Focus Center',
            child: Icon(Icons.location_searching),
          ),
        ],
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
