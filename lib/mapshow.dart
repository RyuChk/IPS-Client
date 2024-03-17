import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'navbar.dart' as CustomNavBar;

class CustomMap extends StatefulWidget {
  @override
  _CustomMapState createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  late latLng.LatLng _center;
  late latLng.LatLng _userCenter;
  late double later;
  late double lnger;
  late double _zoom;
  late MapController _mapController;
  bool _fieldsVisible = true;
  late double _direction; // Direction for the marker rotation

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    // Initial center coordinates and zoom level
    const start_lat = 13.7279936;
    const start_lng = 100.7782921;
    const start_zoom = 21.5;
    _center = latLng.LatLng(start_lat, start_lng);
    _userCenter = latLng.LatLng(start_lat, start_lng);
    _mapController = MapController();
    later = start_lat;
    lnger = start_lng;
    _zoom = start_zoom;
    _direction = 0;
    // Set initial values for text field controllers
    _latitudeController.text = _center.latitude.toString();
    _longitudeController.text = _center.longitude.toString();
    _zoomController.text = _zoom.toString();
    _initializeCompass();
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
    _mapController.move(latLng.LatLng(later, lnger), _zoom);
    print("current direction: $_direction");
  }

  void moveUser() {
    setState(() {
      _userCenter = latLng.LatLng(later, lnger);
    });
  }

  void _updateCenter(String lat, String lng) {
    setState(() {
      _center = latLng.LatLng(double.parse(lat), double.parse(lng));
      later = double.parse(lat);
      lnger = double.parse(lng);
    });
  }

  void _updateZoom(String zoom) {
    setState(() {
      _zoom = double.parse(zoom);
    });
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
          backgroundColor: const Color(0xff68A8E9),
          title: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mode_edit_rounded, color: Colors.white,),
            SizedBox(width: 8,),
             Text('Sandbox', style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter'),),
              ],
            ),

            )
        ),
        body: Column(
          children: [
            if (_fieldsVisible)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.5, // Set opacity here
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      label: Text('Latitude',
                        style: TextStyle(
                            color: Color(0xff242527),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),),
                    ),
                    style: TextStyle(
                        color: Color(0xff242527),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _updateCenter(value, _longitudeController.text),
                  ),
                ),
              ),
            if (_fieldsVisible)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.5, // Set opacity here
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      label: Text('Longitude',
                        style: TextStyle(
                            color: Color(0xff242527),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),),
                    ),
                    style: TextStyle(
                        color: Color(0xff242527),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _updateCenter(_latitudeController.text, value),
                  ),
                ),
              ),
            if (_fieldsVisible)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.5, // Set opacity here
                  child: TextFormField(
                    controller: _zoomController,
                    decoration: InputDecoration(
                      label: Text('Zoom Level',
                        style: TextStyle(
                            color: Color(0xff242527),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),),
                    ),
                    style: TextStyle(
                        color: Color(0xff242527),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateZoom(value),
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
                    items: [
                      const DropdownMenuItem(
                          value: 'focusCenter',
                          child: Icon(
                            Icons.location_searching,
                            color: Colors.white,
                          )
                      ),
                      DropdownMenuItem(
                          value: 'hideFields',
                          child:  Icon(_fieldsVisible ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                            color: Colors.white,
                          )

                      ),
                      const DropdownMenuItem(
                          value: 'moveUser',
                          child: Icon(
                            color: Colors.white,
                            Icons.location_pin,
                          )

                      ),
                    ],
                    onChanged: (value) {
                      switch (value) {
                        case 'focusCenter':
                          moveCenter();
                          break;
                        case 'hideFields':
                          _fieldsVisible = !_fieldsVisible;
                          break;
                        case 'moveUser':
                          moveUser();
                          break;
                      }
                    },

                  )
              ),
            )],
        ),

        // bottomNavigationBar: CustomNavBar.NavigationBar(
        //   currentIndex:
        //       2, // Set the currentIndex according to your needs // Use the NavigationBar widget with the alias
        // )
    );
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
    home: CustomMap(),
  ));
}
