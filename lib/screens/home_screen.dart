import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutterwebapp/screens/web_view_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final bool isInternetConnected;
  const HomeScreen({super.key, required this.isInternetConnected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  int _androidVersion = 0;

  @override
  void initState() {
    super.initState();
    _getAndroidVersion().then((_) => _requestPermission());
  }

  Future<void> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _androidVersion = androidInfo.version.sdkInt;
      });
      print('Android SDK Version: $_androidVersion');
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    bool hasPermission = false;

    try {
      if (Platform.isAndroid) {
        if (_androidVersion >= 33) {
          // Android 13+ (API 33+) - Request specific media permissions
          final List<Permission> permissions = [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ];

          Map<Permission, PermissionStatus> statuses = await permissions.request();
          hasPermission = statuses.values.every((status) => status.isGranted);

          print('Media permissions status: $statuses');
        } else if (_androidVersion >= 30) {
          // Android 11-12 (API 30-32) - Request manage external storage
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
          hasPermission = status.isGranted;

          print('Manage external storage status: $status');
        } else {
          // Android 10 and below - Request storage permission
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          hasPermission = status.isGranted;

          print('Storage permission status: $status');
        }
      } else {
        // For iOS or other platforms
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
        hasPermission = status.isGranted;
      }
    } catch (e) {
      print('Error requesting permission: $e');
      hasPermission = false;
    }

    setState(() {
      _hasPermission = hasPermission;
      _isCheckingPermission = false;
    });

    if (!hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    String permissionText = '';
    String settingsText = '';

    if (_androidVersion >= 33) {
      permissionText = 'This app needs access to photos, videos, and audio files to work properly.';
      settingsText = 'Please enable Photos, Videos, and Audio permissions in Settings.';
    } else if (_androidVersion >= 30) {
      permissionText = 'This app needs file management permission to work properly.';
      settingsText = 'Please enable "All files access" or "Manage all files" permission in Settings.';
    } else {
      permissionText = 'This app needs storage permission to work properly.';
      settingsText = 'Please enable Storage permission in Settings.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Permission Required'),
          content: Text(permissionText),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermission();
              },
              child: const Text('Try Again'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // Wait a bit then check again
                Future.delayed(const Duration(seconds: 2), () {
                  _requestPermission();
                });
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInstructions() {
    String instructions = '';

    if (_androidVersion >= 33) {
      instructions = '''
To enable permissions manually:
1. Go to Settings → Apps → Your App Name
2. Tap on "Permissions"
3. Enable "Photos and videos" and "Music and audio"
4. Return to the app
      ''';
    } else if (_androidVersion >= 30) {
      instructions = '''
To enable file access manually:
1. Go to Settings → Apps → Your App Name
2. Tap on "Permissions" or "Advanced"
3. Look for "All files access" or "Manage all files"
4. Enable it and return to the app
      ''';
    } else {
      instructions = '''
To enable storage permission manually:
1. Go to Settings → Apps → Your App Name
2. Tap on "Permissions"
3. Enable "Storage" permission
4. Return to the app
      ''';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Manual Permission Setup'),
          content: Text(instructions),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermission();
              },
              child: const Text('Check Again'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                Future.delayed(const Duration(seconds: 2), () {
                  _requestPermission();
                });
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isInternetConnected) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                "Please check your internet connection and try again",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isCheckingPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                "Checking permissions...",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Android Version: $_androidVersion",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_off, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  "Permission Required",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _androidVersion >= 33
                      ? "This app needs access to media files to work properly."
                      : _androidVersion >= 30
                      ? "This app needs file management permission to work properly."
                      : "This app needs storage permission to work properly.",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Android Version: $_androidVersion",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _requestPermission,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("Grant Permission"),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _showManualInstructions,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("Manual Setup"),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await openAppSettings();
                        Future.delayed(const Duration(seconds: 2), () {
                          _requestPermission();
                        });
                      },
                      child: const Text("Open App Settings"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const WebViewApp(
      initialUrl: 'https://proyojonershathi.com/',
    );
  }
}