import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authenpage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'navbar.dart' as CustomNavBar;

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late Future<Map<String, String>> _userInfo;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _userInfo = _getUserInfo();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? idToken = prefs.getString('idToken');
    if (accessToken != null && idToken != null) {
      await _verifyToken(accessToken);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthenPage(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    }
  }

  Future<void> _verifyToken(String accessToken) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('https://authentik.cie-ips.com/application/o/userinfo/'),
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode != 200) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AuthenPage(),
            transitionDuration: Duration(seconds: 0),
          ),
        );
      }
    } catch (e) {
      print('Error verifying token: $e');
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthenPage(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    }
  }

  Future<Map<String, String>> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('preferred_username') ?? 'Unknown';
    String? email = prefs.getString('email') ?? 'Unknown';
    String? nickname = prefs.getString('name') ?? 'Unknown';
    return {
      'preferred_username': username,
      'email': email,
      'name': nickname,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff68A8E9),
        title: Container(
          alignment: Alignment.center,
          child:  Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, color: Colors.white),
              SizedBox(width: 8,),
              const Text('Setting', style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter'),),
            ],
          )
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: _userInfo,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, String>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('username:',
                            style: TextStyle(
                                color: Color(0xff242527),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter'),),
                          Text(snapshot.data!['preferred_username'] ?? '', style: TextStyle(
                              color: Color(0xff242527),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter'),),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('email:',
                            style: TextStyle(
                                color: Color(0xff242527),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter'),),
                          Text(snapshot.data!['email'] ?? '', style: TextStyle(
                              color: Color(0xff242527),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter'),),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('name:',
                            style: TextStyle(
                                color: Color(0xff242527),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter'),),
                          Text(snapshot.data!['name'] ?? '', style: TextStyle(
                              color: Color(0xff242527),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter'),),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xff68A8E9), //text color
                  backgroundColor: const Color(0xffF1F1F1), //bg color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
                onPressed: () async {
                  bool? logoutConfirmed = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Log Out'),
                        content: Text('Are you sure logging out?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Log Out'),
                          ),
                        ],
                      );
                    },
                  );
                  if (logoutConfirmed == true) {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => AuthenPage()),
                    );
                  }
                },
                child: Text('LOG OUT'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar.NavigationBar(
        currentIndex: 3,
      ),
    );
  }
}
