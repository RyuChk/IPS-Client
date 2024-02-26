import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

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

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  StreamSubscription<CompassEvent>? _compassSubscription;

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
