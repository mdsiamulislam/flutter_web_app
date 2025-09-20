import 'package:flutter/material.dart';
import 'package:flutterwebapp/core/services/check_connectivity.dart';
import 'package:flutterwebapp/screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isInternetConnected;
  late final CheckConnectivity _checkConnectivity;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkConnectivity = CheckConnectivity();
    // Do one-time initial check
    _checkConnectivity.isInternetAvailable().then((connected) {
      setState(() {
        isInternetConnected = connected;
      });
    });
  }

  // Write a function to take storage permission
  Future<void> _checkPermissions() async {
    // List all permissions you want
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.notification,
    ].request();

    // Optional: print results
    statuses.forEach((permission, status) {
      debugPrint('$permission: $status');
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Internet Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isInternetConnected == null
          ? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      )
          : HomeScreen(isInternetConnected: isInternetConnected!),
    );
  }
}
