import 'package:ipsmain/api/map.dart';

class BuildingInfo {
  final String name;
  final String description;
  final double originLat;
  final double originLong;
  List<Floor> floorList;
  Map<int, FloorDetail> _floorCache;

  BuildingInfo(
      this.name,
      this.description,
      this.originLat,
      this.originLong,
      this.floorList,
      this._floorCache,
  );

  Future<FloorDetail?> getFloorDetail(int floor) async {
    if (_floorCache.containsKey(floor) && _floorCache[floor] != null) {
      return _floorCache[floor];
    } else {
      FloorDetail info = await getFloorDetailFromServer(name, floor);
      _floorCache[floor] = info;
      return info;
    }
  }

  factory BuildingInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'name': String name,
      'description': String description,
      'origin_lat': double originLat,
      'origin_long': double originLong,
      'floor_list': List<Floor> floorList,
      } => BuildingInfo(name, description, originLat, originLong, floorList, {}),
      _ => throw const FormatException('Failed to load UserLocation.'),
    };
  }
}

class Floor {
  final String name;
  final String description;
  final String building;
  final String symbol;
  final int floor;
  final bool isAdmin;

  const Floor({required this.name,
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