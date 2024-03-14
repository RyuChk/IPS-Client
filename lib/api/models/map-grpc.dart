import 'package:ipsmain/api/map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuildingInfo {
  final String name;
  final String description;
  final double originLat;
  final double originLong;
  List<Floor> floorList;

  BuildingInfo(
    this.name,
    this.description,
    this.originLat,
    this.originLong,
    this.floorList,
  );

  Future<FloorDetail?> getFloorDetail(double floor, accessToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var key = "$name:$floor";
    if (prefs.containsKey(key) && prefs?.getString(key) != null) {
      String? floorDetail = prefs.getString(key);
      return FloorDetail.fromJson(json.decode(floorDetail!));
    }

    FloorDetail info = await getFloorDetailFromServer(name, floor, accessToken);
    prefs.setString(key, json.encode(info));

    return info;
  }

  factory BuildingInfo.fromJsonNoFloorList(Map<String, dynamic> json) {
    print("fromJson PRINTER2");
    print(json);
    return switch (json) {
      {
        'name': String name,
        'description': String description,
        'origin_lat': double originLat,
        'origin_long': double originLong,
      } =>
        BuildingInfo(name, description, originLat, originLong, []),
      _ => throw const FormatException('Failed to load UserLocation. 2'),
    };
  }

  factory BuildingInfo.fromJson(Map<String, dynamic> json) {
    print("fromJson PRINTER");
    print(json);

    try {
      String name = json['name'];
      String description = json['description'];
      double originLat = json['origin_lat'];
      double originLong = json['origin_long'];
      List<dynamic> floorListJson = json['floor_list'];
      List<Floor> floorList =
          floorListJson.map((floorJson) => Floor.fromJson(floorJson)).toList();

      return BuildingInfo(name, description, originLat, originLong, floorList);
    } catch (e) {
      print("Error parsing BuildingInfo from JSON: $e");
      throw FormatException('Failed to load BuildingInfo from JSON: $json');
    }
  }
}

class Floor {
  final String name;
  final String description;
  final String building;
  final String symbol;
  final int floor;
  final bool isAdmin;

  const Floor({
    required this.name,
    required this.description,
    required this.building,
    required this.symbol,
    required this.floor,
    required this.isAdmin,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'name': String name,
        'description': String description,
        'building': String building,
        'symbol': String symbol,
        'floor': int floor,
        'is_admin': bool isAdmin,
      } =>
        Floor(
          name: name,
          description: description,
          building: building,
          symbol: symbol,
          floor: floor,
          isAdmin: isAdmin,
        ),
      _ => throw const FormatException('Failed to load UserLocation.'),
    };
  }
}

class FloorDetail {
  Floor info;
  List<Room> room;

  FloorDetail({required this.info, required this.room});

  factory FloorDetail.fromJson(Map<String, dynamic> json) {
    return FloorDetail(
      info: Floor.fromJson(json['info']),
      room: List<Room>.from(json['room'].map((x) => Room.fromJson(x))),
    );
  }
}

class Room {
  String roomId;
  String name;
  String description;
  double latitude;
  double longitude;

  Room({
    required this.roomId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
