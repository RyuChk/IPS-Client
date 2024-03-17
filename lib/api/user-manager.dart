import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ipsmain/api/constants.dart';

import 'package:ipsmain/api/models/user-manager-grpc.dart';

Future<UserLocation> getUserLocation(obj, accessToken) async {
  print("shooting userlocation");
  print(obj);
  print(obj.toString());
  final response = await http.post(
    Uri.parse(userManagerServiceBaseURL),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode(obj), // Encode the object to JSON
  );
  if (response.statusCode == 200) {
    print("userlo2 resp");
    print(response.body);
    return UserLocation.fromJson(jsonDecode(response.body));
  }
  print('resp: $response');
  print(response.statusCode);
  print(response.body);
  return UserLocation(
    x: 0.0,
    y: 0.0,
    z: 0.0,
    building: '',
    label: '',
    originLat: 0.0,
    originLong: 0.0,
  );
}
