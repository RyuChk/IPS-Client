import 'package:latlong2/latlong.dart' as latLng;
import 'dart:math';

const double earthRadius = 6378137;

class OnlineUser {
  final String displayName;
  final Coordinate coordinate;
  final DateTime timestamp;
  final double originLat;
  final double originLong;

  const OnlineUser({
    required this.displayName,
    required this.coordinate,
    required this.timestamp,
    required this.originLat,
    required this.originLong,
  });

  latLng.LatLng get origin => latLng.LatLng(originLat, originLong);

  double get latitude => origin.latitude + ((coordinate.x / earthRadius) * 180 / pi);
  double get longitude =>
      origin.longitude +
          ((coordinate.y / (earthRadius * cos(origin.latitude * pi / 180))) * 180 / pi);
  int get floor => coordinate.z;

  factory OnlineUser.fromJson(Map<String, dynamic> json, double originLat, double originLong) {
    return OnlineUser(
      displayName: json['display_name'],
      coordinate: Coordinate.fromJson(json['coordinate']),
      timestamp: DateTime.parse(json['timestamp']),
      originLat: originLat,
      originLong: originLong,
    );
  }
}

class Coordinate {
  final double x;
  final double y;
  final int z;

  Coordinate({
    required this.x,
    required this.y,
    required this.z
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(x: json['x'], y: json['y'], z: json['z']);
  }
}

class OnlineUserDetail {
  final String displayName;
  // final String locationLabel;

  const OnlineUserDetail({
    required this.displayName,
    // required this.locationLabel
  });

  factory OnlineUserDetail.fromJson(Map<String, dynamic> json) {
    return OnlineUserDetail(
      displayName: json['display_name'],
      // locationLabel: json['label']
    );
  }

}