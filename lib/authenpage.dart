import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mymap.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthenPage(),
    );
  }
}

class AuthenPage extends StatefulWidget {
  @override
  _AuthenPageState createState() => _AuthenPageState();
}

class _AuthenPageState extends State<AuthenPage> {
  bool _isBusy = false;
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  String? _accessToken;
  String? _idToken;
  String? _userInfo;
  late String _email;
  late String _name;
  late String _preferredUsername;

  final String _clientId =
      'XpgS7yXhTLXqP2iMCqAj0UC5611DgvvuN7xUd52F'; // Replace with your client ID
  final String _redirectUrl =
      'com.example.oauthtesting:/oauthredirect'; // Replace with your redirect URI
  final String _issuer =
      'https://authentik.cie-ips.com/application/o/main-application/';
  final String _discoveryUrl =
      'https://authentik.cie-ips.com/application/o/main-application/.well-known/openid-configuration';
  final List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
  ];

  final AuthorizationServiceConfiguration _serviceConfiguration =
      AuthorizationServiceConfiguration(
    authorizationEndpoint:
        'https://authentik.cie-ips.com/application/o/authorize/',
    tokenEndpoint: 'https://authentik.cie-ips.com/application/o/token/',
    endSessionEndpoint:
        'https://authentik.cie-ips.com/application/o/main-application/end-session/',
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the widget initializes
  }

  // Function to check login status
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? idToken = prefs.getString('idToken');
    if (accessToken != null && idToken != null) {
      // Token exists, proceed to verify the token
      await _verifyToken(accessToken);
    } else {
      // If tokens are not available, navigate back to the authentication page
      print("token failed 11");
    }
  }

// Function to verify the token by fetching user info
  Future<void> _verifyToken(String accessToken) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('https://authentik.cie-ips.com/application/o/userinfo/'),
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        // Token is valid, navigate to MyMap
        print("token stil ok");
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MyMap(),
            transitionDuration: Duration(seconds: 0),
          ),
        );
      } else {
        // Token is not valid, navigate back to the authentication page
        print("token failed 22");
      }
    } catch (e) {
      print('Error verifying token: $e');
      // Navigate back to the authentication page in case of any errors
      print("token failed 3");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPS Authentication'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Visibility(
                visible: _isBusy,
                child: const LinearProgressIndicator(),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                child: const Text('ENTER'),
                onPressed: _isBusy ? null : _signIn,
              ),
              const SizedBox(height: 8),
              //const Text('User Info'),
              //Text(_userInfo ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    try {
      _setBusyState();
      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: _serviceConfiguration,
          scopes: _scopes,
          clientSecret:
              'KDWosDL2MvJO1d0PUYrs3aJXlKHw7sxzLkrsBLL6CZoxT6XRGC0CGbQ9MFkfkBL8vwNi35dFMA41ZhrVB5YM2GJEEHCOKrx3P2v0VTxiX0mugfuJYmXwpG1U4GCwjQ5w',
          allowInsecureConnections: true,
        ),
      );

      if (result != null) {
        _processAuthTokenResponse(result);
        await _getUserInfo();
        await _saveAuthDetails();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyMap()),
        );
      }
    } catch (e) {
      print('Error signing in: $e');
      _clearBusyState();
    }
  }

  Future<void> _getUserInfo() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('https://authentik.cie-ips.com/application/o/userinfo/'),
        headers: <String, String>{
          'Authorization': 'Bearer $_accessToken',
        },
      );
      final userInfoJson = jsonDecode(response.body);
      setState(() {
        _userInfo = response.body;
        _email = userInfoJson['email'];
        _name = userInfoJson['name'];
        _preferredUsername = userInfoJson['preferred_username'];
        _isBusy = false;
      });
    } catch (e) {
      print('Error getting user info: $e');
      _clearBusyState();
    }
  }

  Future<void> _saveAuthDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', _accessToken!);
    await prefs.setString('idToken', _idToken!);
    await prefs.setString('email', _email);
    await prefs.setString('name', _name);
    await prefs.setString('preferred_username', _preferredUsername);
  }

  void _clearBusyState() {
    setState(() {
      _isBusy = false;
    });
  }

  void _setBusyState() {
    setState(() {
      _isBusy = true;
    });
  }

  void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _accessToken = response.accessToken;
      _idToken = response.idToken;
    });
  }
}