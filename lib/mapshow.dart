import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'dart:async';
import 'dart:math';
import 'package:sensors/sensors.dart';

class CustomMap extends StatefulWidget {
  @override
  _CustomMapState createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  late latLng.LatLng _center;
  late double later;
  late double lnger;
  late double _zoom;
  late MapController _mapController;
  bool _fieldsVisible = true;
  late double _direction; // Direction for the marker rotation
  late StreamSubscription _accelerometerSubscription;
  late StreamSubscription _gyroscopeSubscription;

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial center coordinates and zoom level
    const start_lat = 13.72765;
    const start_lng = 100.772435;
    const start_zoom = 21.5;
    _center = latLng.LatLng(start_lat, start_lng);
    _mapController = MapController();
    later = start_lat;
    lnger = start_lng;
    _zoom = start_zoom;
    // Set initial values for text field controllers
    _latitudeController.text = _center.latitude.toString();
    _longitudeController.text = _center.longitude.toString();
    _zoomController.text = _zoom.toString();
    _initializeSensors();
  }

  void _initializeSensors() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      // Calculate the direction based on accelerometer data
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double direction = -1 * (180 / 3.14) * atan(y / sqrt(x * x + z * z));

      setState(() {
        _direction = direction;
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Optionally, you can use gyroscope data for more accurate direction calculation
      // double x = event.x;
      // double y = event.y;
      // double z = event.z;
    });
  }

  void moveCenter() {
    _mapController.move(latLng.LatLng(later, lnger), _zoom);
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
        title: Text('Custom Map'),
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
                    labelText: 'Latitude',
                  ),
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
                    labelText: 'Longitude',
                  ),
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
                    labelText: 'Zoom Level',
                  ),
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
                      point: _center,
                      width: 80.0,
                      height: 80.0,
                      rotate: true, // Rotate the marker based on direction
                      alignment: Alignment.center,
                      child: Transform.rotate(
                        angle: _direction *
                            (pi / 180), // Convert degrees to radians
                        child: Icon(
                          Icons.arrow_upward,
                          size: 80.0,
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
              moveCenter();
            },
            tooltip: 'Move to Location',
            child: Icon(Icons.location_searching),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _fieldsVisible = !_fieldsVisible;
              });
            },
            tooltip: _fieldsVisible ? 'Hide Fields' : 'Show Fields',
            child:
                Icon(_fieldsVisible ? Icons.visibility_off : Icons.visibility),
          ),
        ],
      ),
    );
  }

  Marker rotateMarker(double rotation) {
    // return Marker(
    //   width: 80.0,
    //   height: 80.0,
    //   point: _center,
    //   builder: (ctx) => Transform.rotate(
    //     angle: rotation * (3.14 / 180), // Convert to radians for rotation
    //     child: Icon(
    //       Icons.arrow_upward,
    //       size: 80.0,
    //       color: Colors.blue,
    //     ),
    //   ),
    // );
    return Marker(
      point:
          latLng.LatLng(13.72765, 100.772435), // Provide the LatLng coordinates
      child: Icon(Icons.location_pin), // Provide a child widget (e.g., an icon)
    );
  }

  @override
  void dispose() {
    // Dispose text field controllers
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
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
