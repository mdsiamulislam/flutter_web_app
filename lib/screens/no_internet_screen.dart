import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:math' as math;

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onConnectionRestored;
  final String? customMessage;
  final bool autoRetry;

  const NoInternetScreen({
    super.key,
    this.onConnectionRestored,
    this.customMessage,
    this.autoRetry = true,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  bool _isRetrying = false;
  bool _isConnected = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _autoRetryTimer;
  int _retryAttempts = 0;
  final int _maxRetryAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupConnectivityListener();
    if (widget.autoRetry) {
      _startAutoRetry();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for the main icon
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for orbital elements
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Fade animation for text elements
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Bounce animation for success feedback
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));

    _fadeController.forward();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
        final wasConnected = _isConnected;
        setState(() {
          _isConnected = result != ConnectivityResult.none;
        });

        if (!wasConnected && _isConnected) {
          _onConnectionRestored();
        }
      },
    );
  }

  void _startAutoRetry() {
    _autoRetryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_retryAttempts < _maxRetryAttempts && !_isConnected) {
        _retryConnection(isAutoRetry: true);
      } else if (_retryAttempts >= _maxRetryAttempts || _isConnected) {
        timer.cancel();
      }
    });
  }

  Future<void> _onConnectionRestored() async {
    // Play success animation
    await _bounceController.forward();
    await _bounceController.reverse();

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Connection restored!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Call the callback after a short delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (widget.onConnectionRestored != null) {
      widget.onConnectionRestored!();
    }
  }

  Future<void> _retryConnection({bool isAutoRetry = false}) async {
    if (!isAutoRetry) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _isRetrying = true;
      if (!isAutoRetry) _retryAttempts++;
    });

    try {
      // Check actual connectivity
      final connectivityResult = await Connectivity().checkConnectivity();

      // Simulate network check delay for better UX
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isConnected = connectivityResult != ConnectivityResult.none;
        _isRetrying = false;
      });

      if (_isConnected) {
        _onConnectionRestored();
      } else {
        _showRetryFeedback();
      }
    } catch (e) {
      setState(() {
        _isRetrying = false;
      });
      _showRetryFeedback();
    }
  }

  void _showRetryFeedback() {
    if (!mounted) return;

    final remainingAttempts = _maxRetryAttempts - _retryAttempts;
    final message = remainingAttempts > 0
        ? 'Still no connection. $remainingAttempts attempt${remainingAttempts == 1 ? '' : 's'} remaining.'
        : 'Still no connection. Please check your network settings.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: remainingAttempts <= 0
            ? SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: _openNetworkSettings,
        )
            : null,
      ),
    );
  }

  void _openNetworkSettings() {
    // This would open device network settings
    // You can implement this using url_launcher or similar packages
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening network settings...'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _resetRetryAttempts() {
    setState(() {
      _retryAttempts = 0;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _connectivitySubscription?.cancel();
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background elements
            ...List.generate(5, (index) => _buildOrbitingElement(index)),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated main icon with bounce effect
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value * _bounceAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isConnected
                                    ? [Colors.green.shade400, Colors.teal.shade600]
                                    : isDark
                                    ? [Colors.cyan.shade400, Colors.blue.shade600]
                                    : [Colors.blue.shade400, Colors.indigo.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isConnected
                                      ? Colors.green
                                      : isDark
                                      ? Colors.cyan
                                      : Colors.blue).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isConnected
                                  ? Icons.wifi_rounded
                                  : Icons.wifi_off_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _isConnected ? 'Connection Restored!' : 'No Internet Connection',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isConnected
                              ? Colors.green.shade600
                              : isDark
                              ? Colors.white
                              : Colors.grey.shade800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.customMessage ??
                            (_isConnected
                                ? 'You\'re back online! Redirecting you shortly...'
                                : 'Please check your connection and try again.\nMake sure you\'re connected to Wi-Fi or mobile data.'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Retry button (hide if connected)
                    if (!_isConnected) ...[
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: ElevatedButton(
                            onPressed: _isRetrying ? null : () => _retryConnection(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.cyan.shade600 : Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: (isDark ? Colors.cyan : Colors.blue).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child: _isRetrying
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Checking...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _retryAttempts >= _maxRetryAttempts
                                      ? 'Try Again'
                                      : 'Try Again (${_retryAttempts + 1}/$_maxRetryAttempts)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Additional options
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: _openNetworkSettings,
                              icon: Icon(
                                Icons.settings_rounded,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                size: 18,
                              ),
                              label: Text(
                                'Settings',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _resetRetryAttempts,
                              icon: Icon(
                                Icons.refresh,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                size: 18,
                              ),
                              label: Text(
                                'Reset',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Auto-retry indicator
                    if (widget.autoRetry && !_isConnected) ...[
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.grey.shade800 : Colors.grey.shade200).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? Colors.cyan.shade400 : Colors.blue.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Auto-retry enabled',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitingElement(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _isConnected
        ? [Colors.green.shade400, Colors.teal.shade400, Colors.lightGreen.shade400, Colors.pink.shade400, Colors.cyan.shade300]
        : isDark
        ? [Colors.cyan.shade400, Colors.blue.shade400, Colors.purple.shade400, Colors.indigo.shade400, Colors.teal.shade400]
        : [Colors.blue.shade300, Colors.indigo.shade300, Colors.purple.shade300, Colors.cyan.shade300, Colors.teal.shade300];

    final sizes = [8.0, 6.0, 10.0, 5.0, 7.0];
    final radiuses = [150.0, 200.0, 120.0, 180.0, 220.0];
    final speeds = [1.0, -0.7, 1.3, -1.1, 0.9];

    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        final angle = _rotationAnimation.value * speeds[index];
        return Positioned(
          left: MediaQuery.of(context).size.width / 2 +
              math.cos(angle) * radiuses[index] - sizes[index] / 2,
          top: MediaQuery.of(context).size.height / 2 +
              math.sin(angle) * radiuses[index] - sizes[index] / 2,
          child: Container(
            width: sizes[index],
            height: sizes[index],
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[index % colors.length].withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: colors[index % colors.length].withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}