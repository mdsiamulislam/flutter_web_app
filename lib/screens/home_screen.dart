import 'package:flutter/cupertino.dart';
import 'package:flutterwebapp/screens/web_view_app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const WebViewApp(
      initialUrl: 'https://proyojonershathi.com/',
    );
  }
}