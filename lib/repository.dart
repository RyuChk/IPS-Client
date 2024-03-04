import 'dart:convert';

import 'package:latlong2/latlong.dart' as latLng;
import 'dart:math';

const double earthRadius = 6378137;
double latOrigin = 13.72778;
double lngOrigin = 100.77238;
var origin = latLng.LatLng(latOrigin, lngOrigin);

class UserLocation {
  double _x;
  double _y;
  double _z;
  String label;
  String building;

  UserLocation(this._x, this._y, this._z, this.label, this.building);

  double get latitude => origin.latitude + ((_x / earthRadius) * 180 / pi);
  double get longitude =>
      origin.longitude +
      ((_y / (earthRadius * cos(origin.latitude * pi / 180))) * 180 / pi);
  double get floor => _z;

  void fetchLocation() {
    String jsonString = '''
  {
    "x": "0",
    "y": "0",
    "z": "1",
    "origin_lat":"13.72778",
    "origin_lng":"100.77238",
    "building":"CMKL Buidling",
    "label":"Corridor"
  }
  ''';

    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _x = double.parse(jsonMap["x"]);
    _y = double.parse(jsonMap["y"]);
    _z = double.parse(jsonMap["z"]);
    latOrigin = double.parse(jsonMap["origin_lat"]);
    lngOrigin = double.parse(jsonMap["origin_lng"]);
    label = jsonMap["label"];
    building = jsonMap["building"];
    origin = latLng.LatLng(latOrigin, lngOrigin);
  }
}
