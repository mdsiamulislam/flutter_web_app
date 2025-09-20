import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class WebViewApp extends StatefulWidget {
  final String initialUrl;

  const WebViewApp({
    super.key,
    this.initialUrl = 'https://proyojonershathi.com/',
  });

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late WebViewController _controller;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isOffline = false;
  String _currentUrl = '';
  String _currentTitle = 'Loading...';
  double _loadingProgress = 0.0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  final TextEditingController _urlController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _showUrlBar = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _currentUrl = url;
            });
            _updateNavigationButtons();
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            _getPageTitle();
            _updateNavigationButtons();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            Uri initialUri = Uri.parse(widget.initialUrl);
            Uri requestUri = Uri.parse(request.url);

            // Check if parent domain (host) is different
            if (requestUri.host != initialUri.host) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }

            // Handle mailto, tel, sms as before
            if (request.url.startsWith('mailto:') ||
                request.url.startsWith('tel:') ||
                request.url.startsWith('sms:')) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FileUpload',
        onMessageReceived: (JavaScriptMessage message) {
          _handleFileUpload();
        },
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
        setState(() {
          _isOffline = result == ConnectivityResult.none;
        });

        if (!_isOffline && _hasError) {
          _refreshPage();
        }
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _getPageTitle() async {
    final title = await _controller.getTitle();
    setState(() {
      _currentTitle = title ?? 'Untitled';
    });
  }

  Future<void> _updateNavigationButtons() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _launchExternalUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _handleFileUpload() async {
    try {

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        // Handle file upload logic here
        _showSnackBar('Files selected: ${result.files.length}');

        // You can process the files here
        for (var file in result.files) {
          print('File: ${file.name}, Size: ${file.size} bytes');
        }
      }
    } catch (e) {
      _showSnackBar('Error selecting files: $e');
    }
  }


  // Fixed share function
  void _shareCurrentPage()async{
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Check out this page: $_currentUrl',
          subject: _currentTitle,
        )
      );
    } catch (e) {
      _showSnackBar('Share failed: $e');
    }
  }

  Future<void> captureAndShareScreenshot() async {
    try {

      // Capture screenshot
      final image = await _screenshotController.capture();
      if (image == null) {
        _showSnackBar('Failed to capture screenshot');
        return;
      }

      // Save to app documents
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/screenshot_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(image);

      // Share the screenshot
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this page: $_currentTitle',
        subject: _currentTitle,
      );

      _showSnackBar('Screenshot captured and shared!');
    } catch (e) {
      debugPrint("Screenshot error: $e");
      _showSnackBar('Screenshot failed: $e');
    }
  }

  // Copy URL to clipboard
  Future<void> _copyUrlToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _currentUrl));
      _showSnackBar('URL copied to clipboard');
    } catch (e) {
      _showSnackBar('Failed to copy URL: $e');
    }
  }

  void _refreshPage() {
    _controller.reload();
  }

  void _goBack() {
    if (_canGoBack) {
      _controller.goBack();
    }
  }

  void _goForward() {
    if (_canGoForward) {
      _controller.goForward();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.share,
              title: 'Share Page',
              onTap: () {
                Navigator.pop(context);
                _shareCurrentPage();
              },
            ),
            _buildOptionTile(
              icon: Icons.refresh,
              title: 'Refresh',
              onTap: () {
                Navigator.pop(context);
                _refreshPage();
              },
            ),
            _buildOptionTile(
              icon: Icons.link,
              title: 'Copy URL',
              onTap: () {
                Navigator.pop(context);
                _copyUrlToClipboard();
              },
            ),
            _buildOptionTile(
              icon: Icons.camera_alt,
              title: 'Take Screenshot',
              onTap: () {
                Navigator.pop(context);
                captureAndShareScreenshot();
              },
            ),
            _buildOptionTile(
              icon: Icons.arrow_back,
              title: 'Go Back',
              onTap: _canGoBack ? () {
                Navigator.pop(context);
                _goBack();
              } : null,
            ),
            _buildOptionTile(
              icon: Icons.arrow_forward,
              title: 'Go Forward',
              onTap: _canGoForward ? () {
                Navigator.pop(context);
                _goForward();
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: onTap != null ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: onTap != null ? null : Colors.grey,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isOffline) {
      return _buildOfflineScreen();
    }

    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false; // prevent app from closing
        }
        return true; // exit the app
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFF298fa3),
          foregroundColor: isDark ? Colors.white : Colors.black,
          centerTitle: true,
          elevation: 2,
          title: Text(
            _currentTitle,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Poppins'),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            onPressed: _showOptionsMenu,
            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          ),
          actions: [
            IconButton(
              onPressed: _shareCurrentPage,
              icon: const Icon(Icons.share, color: Colors.white, size: 30),
            ),
          ],
          bottom: PreferredSize(
            preferredSize:
            Size.fromHeight(_showUrlBar ? 60 : (_isLoading ? 4 : 0)),
            child: _isLoading
                ? LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.transparent,
              valueColor:
              AlwaysStoppedAnimation<Color>(theme.primaryColor),
            )
                : const SizedBox.shrink(),
          ),
        ),
        body: _hasError
            ? _buildErrorScreen()
            : RefreshIndicator(
          onRefresh: () async {
            _refreshPage();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: Screenshot(
            controller: _screenshotController,
            child: WebViewWidget(controller: _controller),
          ),
        ),
        floatingActionButton: _isLoading
            ? FloatingActionButton(
          mini: true,
          onPressed: () => _controller.reload(),
          child: const Icon(Icons.stop),
        )
            : null,
      ),
    );
  }


  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load page',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your internet connection and try again.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your connection and try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkConnectivity,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _urlController.dispose();
    super.dispose();
  }
}