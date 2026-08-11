import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../game/dino_game.dart';
import '../../managers/coin_manager.dart';
import '../../managers/audio_manager.dart';
import 'pause_menu.dart';
import 'settings_dialog.dart';

class SplashScreen extends StatefulWidget {
  final CoinManager coinManager;
  const SplashScreen({super.key, required this.coinManager});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleController.forward();
    _progressController.forward().then((_) {
      _navigateToGame();
    });
  }

  void _navigateToGame() {
    final game = DinoGame(coinManager: widget.coinManager);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Listener(
              onPointerDown: (_) => AudioManager.ensureAudioPlaying(),
              child: Scaffold(
                body: PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    game.togglePause();
                  },
                  child: GameWidget<DinoGame>(
                    game: game,
                    overlayBuilderMap: {
                      'PauseMenu': (BuildContext context, DinoGame game) {
                        return PauseMenu(game: game);
                      },
                      'SettingsDialog': (BuildContext context, DinoGame game) {
                        return SettingsDialog(
                          onClose: () {
                            game.overlays.remove('SettingsDialog');
                          },
                        );
                      },
                    },
                    autofocus: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A091B),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient & Glowing Nebula
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF221F57),
                    Color(0xFF0F0E2A),
                    Color(0xFF060511),
                  ],
                ),
              ),
            ),
          ),

          // Floating background star particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StarFieldPainter(time: _floatController.value),
                );
              },
            ),
          ),

          // Main Hero Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Floating Animated Icon with Glowing Energy Aura
                AnimatedBuilder(
                  animation: Listenable.merge([_scaleController, _floatController]),
                  builder: (context, child) {
                    final floatY = math.sin(_floatController.value * math.pi * 2) * 10.0;
                    return Transform.translate(
                      offset: Offset(0, floatY),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4DEEEA).withValues(alpha: 0.45),
                                  blurRadius: 35,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF764BA2).withValues(alpha: 0.35),
                                  blurRadius: 60,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Game Title with Neon Gradient Glow
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFF7B00),
                      Color(0xFF4DEEEA),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'DINO RUN: EPOCHS',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'JOURNEY THROUGH TIME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 38),

                // Loading Bar & Progress Text
                SizedBox(
                  width: math.min(size.width * 0.45, 260.0),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          final pct = (_progressController.value * 100).toInt();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'INITIALIZING EPOCHS...',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4DEEEA).withValues(alpha: 0.9),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Glowing Progress Bar
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white10,
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _progressController.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF764BA2),
                                          Color(0xFF4DEEEA),
                                          Color(0xFFFFD700),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4DEEEA).withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final double time;
  _StarFieldPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();

    for (int i = 0; i < 45; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 1.0 + rng.nextDouble() * 2.5;
      final speed = 0.5 + rng.nextDouble() * 2.0;
      final alpha = (0.2 + math.sin((time * speed + i) * math.pi * 2) * 0.4 + 0.4).clamp(0.1, 0.95);

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => oldDelegate.time != time;
}
