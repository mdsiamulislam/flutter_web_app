import 'package:flutter/material.dart';
import 'package:flutterwebapp/core/services/check_connectivity.dart';
import 'package:flutterwebapp/screens/home_screen.dart';
import 'package:flutterwebapp/screens/no_internet_screen.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();

  CheckConnectivity checkConnectivity = CheckConnectivity();
  bool isInternetConnected = await checkConnectivity.isInternetAvailable();

  runApp(MyApp( isInternetConnected : isInternetConnected));
}

class MyApp extends StatelessWidget {
  bool isInternetConnected;
  MyApp({super.key,required this.isInternetConnected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Internet Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isInternetConnected ? HomeScreen() : NoInternetScreen(),
    );
  }
}
