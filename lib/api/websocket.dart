import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ipsmain/api/models/user-manager-grpc.dart';

const String baseURL = 'wss://bff-api.cie-ips.com';

class UserManagerWS {
  final String url;
  UserLocation? userLocation;
  WebSocketChannel? _channel;

  UserManagerWS(this.url);

  Future<void> connect() async {
    try {
      _channel = IOWebSocketChannel.connect(url);
      print('Connected to WebSocket server');

      // Listen for incoming messages
      _channel!.stream.listen((message) {
        print('Received message: $message');
        // Handle incoming messages here (e.g., parse JSON)
      }, onDone: () {
        print('WebSocket connection closed');
      });
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  // Close the WebSocket connection
  void close() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }
}