import 'package:latlong2/latlong.dart' as latLng;
import 'dart:math';

const double earthRadius = 6378137;
const String baseURL = "https://bff-api.cie-ips.com";

class UserLocation {
  final double x;
  final double y;
  final double z;
  final double originLat;
  final double originLong;
  final String label;
  final String building;

  const UserLocation({
    required this.x,
    required this.y,
    required this.z,
    required this.originLat,
    required this.originLong,
    required this.label,
    required this.building,
  });

  latLng.LatLng get origin => latLng.LatLng(originLat, originLong);

  double get latitude => origin.latitude + ((x / earthRadius) * 180 / pi);
  double get longitude =>
      origin.longitude +
      ((x / (earthRadius * cos(origin.latitude * pi / 180))) * 180 / pi);
  double get floor => z;

  // factory UserLocation.fromJson(Map<String, dynamic> json) {
  //   return switch (json) {
  //     {
  //       'x': double x,
  //       'y': double y,
  //       'z': double z,
  //       'label': String label,
  //       'building': String building,
  //     } =>
  //       UserLocation(
  //         x: x,
  //         y: y,
  //         z: z,
  //         originLat: 0, // Set default value for originLat
  //         originLong: 0, // Set default value for originLong
  //         label: label,
  //         building: building,
  //       ),
  //     _ => throw const FormatException('Failed to load UserLocation.'),
  //   };
  // }
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    print("new json loader userloly");
    return UserLocation(
      x: json['x'],
      y: json['y'],
      z: json['z'],
      originLat: json['origin_lat'] ??
          0, // Use default value if 'origin_lat' is missing
      originLong: json['origin_long'] ??
          0, // Use default value if 'origin_long' is missing
      label: json['label'],
      building: json['building'],
    );
  }
}
