import 'package:flutter/material.dart';
import 'dart:math' as math;

class LogoPreloader extends StatefulWidget {
  // Replace this with your actual logo asset path
  final String logoAssetPath;
  final Duration duration;
  final VoidCallback? onComplete;

  const LogoPreloader({
    super.key,
    this.logoAssetPath = 'assets/images/logo.png', // 👈 Change this to your logo path
    this.duration = const Duration(seconds: 3),
    this.onComplete,
  });

  @override
  State<LogoPreloader> createState() => _LogoPreloaderState();
}

class _LogoPreloaderState extends State<LogoPreloader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _progressController;
  late AnimationController _fadeController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for outer rings
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Pulse animation for glow effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for logo entrance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Progress animation
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Fade animation for completion
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeController.forward().then((_) {
          if (widget.onComplete != null) {
            widget.onComplete!();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(5, (index) => _buildBackgroundParticle(index, size, isDark)),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animated rings
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 200 * _pulseAnimation.value,
                                  height: 200 * _pulseAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isDark ? Colors.cyan : Colors.blue)
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: _RingPainter(
                                      progress: _progressAnimation.value,
                                      color: isDark ? Colors.cyan : Colors.blue,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Inner rotating ring (opposite direction)
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_rotationAnimation.value * 0.7,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (isDark ? Colors.purple : Colors.indigo)
                                      .withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Logo container with glow effect
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? Colors.cyan : Colors.blue)
                                            .withOpacity(0.3 * _pulseAnimation.value),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                            Colors.cyan.shade400,
                                            Colors.blue.shade600,
                                          ]
                                              : [
                                            Colors.blue.shade400,
                                            Colors.indigo.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Image.asset(
                                        widget.logoAssetPath, // 👈 Your logo will appear here
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback icon if logo not found
                                          return Icon(
                                            Icons.flutter_dash,
                                            size: 40,
                                            color: Colors.white,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Loading text
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _scaleAnimation.value,
                        child: Text(
                          'Loading...',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 200 * _progressAnimation.value,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.cyan.shade400, Colors.blue.shade600]
                                    : [Colors.blue.shade400, Colors.indigo.shade600],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Progress percentage
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundParticle(int index, Size size, bool isDark) {
    final colors = isDark
        ? [Colors.cyan, Colors.blue, Colors.purple, Colors.indigo, Colors.teal]
        : [Colors.blue, Colors.indigo, Colors.purple, Colors.deepPurple, Colors.cyan];

    final positions = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.3),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
    ];

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned(
          left: positions[index].dx,
          top: positions[index].dy,
          child: Container(
            width: 4 + (2 * _pulseAnimation.value),
            height: 4 + (2 * _pulseAnimation.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[index].withOpacity(0.4 * _pulseAnimation.value),
              boxShadow: [
                BoxShadow(
                  color: colors[index].withOpacity(0.2),
                  blurRadius: 8,
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

// Custom painter for the progress ring
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Progress angle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Usage example:
// class MyApp extends StatefulWidget {
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   bool _showPreloader = true;
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: _showPreloader
//           ? LogoPreloader(
//               logoAssetPath: 'assets/images/your_logo.png', // 👈 Change this
//               duration: const Duration(seconds: 3),
//               onComplete: () {
//                 setState(() {
//                   _showPreloader = false;
//                 });
//               },
//             )
//           : YourMainScreen(),
//     );
//   }
// }