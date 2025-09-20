import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterwebapp/core/services/check_connectivity.dart';
import 'package:flutterwebapp/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (optional)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool? isInternetConnected;
  late final CheckConnectivity _checkConnectivity;
  bool _isCheckingConnectivity = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity = CheckConnectivity();
    _performInitialConnectivityCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-check connectivity when app comes back to foreground
      _performConnectivityCheck();
    }
  }

  Future<void> _performInitialConnectivityCheck() async {
    try {
      final connected = await _checkConnectivity.isInternetAvailable();
      if (mounted) {
        setState(() {
          isInternetConnected = connected;
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      // Handle any errors during connectivity check
      if (mounted) {
        setState(() {
          isInternetConnected = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  Future<void> _performConnectivityCheck() async {
    try {
      final connected = await _checkConnectivity.isInternetAvailable();
      if (mounted && connected != isInternetConnected) {
        setState(() {
          isInternetConnected = connected;
        });
      }
    } catch (e) {
      // Handle connectivity check errors silently for background checks
      debugPrint('Connectivity check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyojon Er Shathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isCheckingConnectivity || isInternetConnected == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Checking connectivity...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return HomeScreen(isInternetConnected: isInternetConnected!);
  }
}