import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ipsmain/api/models/map-grpc.dart';
import 'package:ipsmain/api/constants.dart';

Future<Map<String, BuildingInfo>> getBuildingList() async {
  final response = await http
    .get(Uri.parse("$mapServiceBaseURL/building"));
  if (response.statusCode == 200) {
    Map<String,BuildingInfo> result = {};
    List<dynamic> data = jsonDecode(response.body);

    for (var element in data) {
      BuildingInfo info = BuildingInfo.fromJson(element);
      result[info.name] = info;
    }

    return result;
  }
  return {};
}

Future<BuildingInfo> getBuildingInfo(String building) async {
  final response = await http
      .get(Uri.parse("$mapServiceBaseURL/info/$building"));
  if (response.statusCode == 200) {
    return BuildingInfo.fromJson(jsonDecode(response.body));
  }
  return BuildingInfo(
    '',           // Empty string for name
    '',           // Empty string for description
    0.0,          // 0.0 for originLat
    0.0,          // 0.0 for originLong
    [],           // Empty list for floorList
    {},           // Empty map for _floorCache
  );
}

Future<FloorDetail> getFloorDetailFromServer(String building, int floor) async {
  final response = await http
      .get(Uri.parse("$mapServiceBaseURL/info/$building/$floor"));
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