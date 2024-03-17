import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ipsmain/api/models/map-grpc.dart';
import 'package:ipsmain/api/constants.dart';

Future<Map<String, BuildingInfo>> getBuildingList(accessToken) async {
  final response = await http.get(
    Uri.parse("$mapServiceBaseURL/building"),
    headers: {
      'Authorization': 'Bearer $accessToken', // Add your access token here
    },
  );

  if (response.statusCode == 200) {
    Map<String, BuildingInfo> result = {};
    List<dynamic> data = jsonDecode(response.body);
    print('data: $data');
    for (var element in data) {
      BuildingInfo info = BuildingInfo.fromJsonNoFloorList(element);
      result[info.name] = info;
    }
    print('result: $result');
    return result;
  }
  print("get allBuilding err");
  print(response);
  print(response.statusCode);
  return {};
}

Future<BuildingInfo> getBuildingInfo(String building, accessToken) async {
  print("uri");
  print("$mapServiceBaseURL/info/$building");
  final response = await http.get(
    Uri.parse("$mapServiceBaseURL/info/$building"),
    headers: {
      'Authorization': 'Bearer $accessToken', // Add your access token here
    },
  );
  if (response.statusCode == 200) {
    return BuildingInfo.fromJson(jsonDecode(response.body));
  }
  print(response.statusCode);
  return BuildingInfo(
    '', // Empty string for name
    '', // Empty string for description
    0.0, // 0.0 for originLat
    0.0, // 0.0 for originLong
    [], // Empty list for floorList
  );
}

Future<FloorDetail> getFloorDetailFromServer(
    String building, double floor, accessToken) async {
  int floorInt = floor.toInt();
  final response = await http.get(
    Uri.parse("$mapServiceBaseURL/info/$building/$floorInt"),
    headers: {
      'Authorization': 'Bearer $accessToken', // Add your access token here
    },
  );
  print("resp floor detail server");
  print(response.statusCode);
  print(response.body);
  if (response.statusCode == 200) {
    return FloorDetail.fromJson(jsonDecode(response.body));
  } else {
    return FloorDetail(
      info: const Floor(
        name: '',
        description: '',
        floor: 0,
        symbol: '',
        building: '',
        isAdmin: false,
      ),
      room: [],
    );
  }
}

