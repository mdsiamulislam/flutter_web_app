import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterwebapp/screens/web_view_app.dart';

class HomeScreen extends StatelessWidget {
  final bool isInternetConnected;
  const HomeScreen({super.key, required this.isInternetConnected});

  @override
  Widget build(BuildContext context) {
    print('isInternetConnected: $isInternetConnected');
    if (!isInternetConnected) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No Internet Connection",
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return const WebViewApp(
      initialUrl: 'https://proyojonershathi.com/',
    );
  }
}
