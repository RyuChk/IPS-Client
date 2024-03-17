import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ipsmain/api/models/user-tracking-grpc.dart';
import 'package:ipsmain/api/constants.dart';

Future<List<OnlineUser>> getOnlineUser(String building, int floor, accessToken, double originLat, double originLong) async {
  final response = await http.get(
    Uri.parse("$adminServiceBaseURL/online/$building/$floor"),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );
  if (response.statusCode == 200) {
    List<dynamic> json = jsonDecode(response.body);
    print(json);
    return json.map((userJson) => OnlineUser.fromJson(userJson, originLat, originLong)).toList();
  }
  return [];
}

Future<List<OnlineUserDetail>> getAllOnlineUsers(String accessToken) async {
  final response = await http.get(
    Uri.parse("$adminServiceBaseURL/online/"),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );
  if (response.statusCode == 200) {
    List<dynamic> json = jsonDecode(response.body);
    print(json);
    return json.map((userJson) => OnlineUserDetail.fromJson(userJson)).toList();
  }
  return [];
}