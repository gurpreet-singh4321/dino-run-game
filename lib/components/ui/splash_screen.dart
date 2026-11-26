import '../../utils/gear_assets.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../../game/dino_game.dart';
import '../../managers/coin_manager.dart';
import '../../managers/audio_manager.dart';
import '../../skins/new_dino_skin.dart';
import '../../utils/scenery_cache.dart';
import '../../utils/boot_handoff.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';
import 'pause_menu.dart';
import 'settings_dialog.dart';
import 'main_menu_overlay.dart';
import 'run_results.dart';

class SplashScreen extends StatefulWidget {
  final CoinManager coinManager;
  const SplashScreen({super.key, required this.coinManager});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  int completed = 0;
  bool ready = false;
  bool _handedOff = false;
  ui.Image? scenery;
  ui.Image? bootDino;
  String? error;
  static const total = 9;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: 0.28,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _step() {
    if (!mounted) return;
    setState(() => completed++);
    final target = (0.28 + 0.72 * (completed / total)).clamp(0.28, 1.0);
    _progress.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _completeWebHandoff() {
    if (_handedOff) return;
    _handedOff = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => finishDinoBoot());
  }

  Future<ui.Image> _loadBootDino() async {
    final bytes = await rootBundle.load('assets/images/boot_dino.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> _load() async {
    setState(() {
      completed = 0;
      error = null;
    });
    _progress.value = 0.28;
    try {
      // Reveal the Flutter splash once the matching desert backdrop and boot
      // Dino cutout are decoded so removing the HTML overlay has zero pop.
      try {
        final results = await Future.wait([
          SceneryCache.load(SceneryCache.paths.first),
          _loadBootDino(),
        ]);
        if (mounted) {
          setState(() {
            scenery = results[0];
            bootDino = results[1];
          });
        }
      } catch (_) {}
      if (!mounted) return;
      _step();
      _completeWebHandoff();

      await Future.wait([
        GearAssets.preload().then((_) => _step()),
        NewDinoSkin.preload().then((_) {
          if (mounted) setState(() => ready = true);
          _step();
        }),
        ...SceneryCache.paths.skip(1).map((name) async {
          // Optional scenery can fall back to the game's native painted sky.
          try {
            await SceneryCache.load(name);
          } catch (_) {}
          _step();
        }),
      ]);
      // Music warming does not hold the first screen behind six audio downloads.
      unawaited(AudioManager.preloadAll().catchError((Object _) {}));
      if (!mounted) return;
      unawaited(
        precacheImage(EpochScenery.imageFor(0), context).catchError((Object _) {}),
      );
      await _progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 340),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
                child: GamePlayScreen(
                  coinManager: widget.coinManager,
                  initialScenery: scenery,
                  initialBootDino: bootDino,
                ),
              ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Dino could not load. Try again.');
        _completeWebHandoff();
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, _) => SplashArtwork(
      scenery: scenery,
      bootDino: bootDino,
      ready: ready,
      animateEntrance: false,
      progress: _progress.value,
      error: error,
      onRetry: _load,
    ),
  );
}

/// The real loading screen, separately renderable for compact-device review.
class SplashArtwork extends StatefulWidget {
  final ui.Image? scenery;
  final ui.Image? bootDino;
  final bool ready, animateEntrance;
  final double progress;
  final String? error;
  final VoidCallback? onRetry;
  const SplashArtwork({
    super.key,
    this.scenery,
    this.bootDino,
    this.ready = false,
    this.animateEntrance = true,
    this.progress = 0,
    this.error,
    this.onRetry,
  });
  @override
  State<SplashArtwork> createState() => _SplashArtworkState();
}

class _SplashArtworkState extends State<SplashArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    value: widget.animateEntrance ? 0 : 1,
  );
  @override
  void initState() {
    super.initState();
    if (widget.animateEntrance) entrance.forward();
  }
  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) entrance.value = 1;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF19283D),
    body: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF17263B),
                  Color(0xFF283D5B),
                  Color(0xFF43374B),
                ],
                stops: [0, .55, 1],
              ),
            ),
          ),
        ),
        if (widget.scenery != null)
          Positioned.fill(
            child: RawImage(
              image: widget.scenery,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF142235).withValues(alpha: .70),
                  const Color(0xFF121D2D).withValues(alpha: .48),
                  const Color(0xFF0E1724).withValues(alpha: .72),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final small = bounds.maxHeight < 290;
              final portrait = bounds.maxWidth < 560;
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: small ? 16 : 24,
                    vertical: small ? 10 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: AnimatedBuilder(
                      animation: entrance,
                      builder: (context, child) {
                        final t = Curves.easeOutCubic.transform(entrance.value);
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 18),
                            child: child,
                          ),
                        );
                      },
                      child: Builder(
                        builder: (context) {
                          final dinoStage = RepaintBoundary(
                            child: SizedBox(
                              height: small ? 155 : (portrait ? 175 : 275),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Positioned(
                                    bottom: 2,
                                    width: small ? 140 : 220,
                                    height: small ? 24 : 36,
                                    child: const CustomPaint(
                                      painter: _SplashLedgePainter(),
                                    ),
                                  ),
                                  Positioned.fill(
                                    bottom: small ? 6 : 12,
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 240 / 280,
                                        child: widget.bootDino != null
                                            ? RawImage(
                                                image: widget.bootDino,
                                                fit: BoxFit.contain,
                                              )
                                            : Image.asset(
                                                'assets/images/boot_dino.png',
                                                fit: BoxFit.contain,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          final card = SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomPaint(
                                  painter: const PlaqueBadgePainter(
                                    top: Color(0xFF2B3E59),
                                    mid: MenuPalette.slate,
                                    bottom: Color(0xFF152132),
                                    outline: Color(0xFF0C121A),
                                    lip: Color(0xFF0A1018),
                                    innerRim: Color(0xDDD8AE5E),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      small ? 18 : 24,
                                      small ? 6 : 9,
                                      small ? 18 : 24,
                                      small ? 11 : 14,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: small ? 26 : 36,
                                            fontWeight: FontWeight.w800,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0xDD0B111A),
                                                offset: Offset(0, 2.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: 'Dino Run ',
                                              style: TextStyle(color: Color(0xFFFFF8E6)),
                                            ),
                                            TextSpan(
                                              text: 'Epochs',
                                              style: TextStyle(color: MenuPalette.gold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: small ? 8 : 12),
                                MenuPaper(
                                  accent: MenuPalette.gold,
                                  padding: EdgeInsets.fromLTRB(
                                    small ? 14 : 18,
                                    small ? 10 : 14,
                                    small ? 14 : 18,
                                    small ? 12 : 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Adventure awaits.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: small ? 15 : 17,
                                          fontWeight: FontWeight.w700,
                                          color: MenuPalette.ink,
                                        ),
                                      ),
                                      SizedBox(height: small ? 8 : 12),
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D2C42),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFC2974D),
                                            width: 1.6,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: widget.progress,
                                            minHeight: small ? 8 : 10,
                                            color: MenuPalette.gold,
                                            backgroundColor: const Color(0xFF2B3E58),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: small ? 6 : 9),
                                      Text(
                                        widget.error ??
                                            (widget.ready
                                                ? 'Preparing the epochs…'
                                                : 'Waking up Dino…'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: widget.error != null
                                              ? MenuPalette.red
                                              : MenuPalette.muted,
                                          fontWeight: FontWeight.w700,
                                          fontSize: small ? 12 : 13,
                                        ),
                                      ),
                                      if (widget.error != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: small ? 8 : 12),
                                          child: Center(
                                            child: FilledButton(
                                              style: adventureButtonStyle(MenuPalette.terracotta),
                                              onPressed: widget.onRetry,
                                              child: const Text('Try again'),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                          return portrait
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    dinoStage,
                                    const SizedBox(height: 10),
                                    Flexible(child: card),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(flex: 4, child: dinoStage),
                                    SizedBox(width: small ? 14 : 24),
                                    Expanded(flex: 5, child: card),
                                  ],
                                );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _SplashLedgePainter extends CustomPainter {
  const _SplashLedgePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    canvas.drawOval(
      Offset.zero & size,
      p
        ..shader = const RadialGradient(
          colors: [Color(0x9C0B1018), Color(0x450B1018), Color(0x000B1018)],
          stops: [0, .58, 1],
        ).createShader(Offset.zero & size),
    );
    p.shader = null;
    final path = Path()
      ..moveTo(size.width * .10, size.height * .66)
      ..quadraticBezierTo(size.width * .24, size.height * .22, size.width * .50, size.height * .24)
      ..quadraticBezierTo(size.width * .76, size.height * .22, size.width * .90, size.height * .66)
      ..quadraticBezierTo(size.width * .50, size.height * .82, size.width * .10, size.height * .66)
      ..close();
    canvas.drawPath(
      path,
      p
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE09C764D), Color(0xDD583F2A), Color(0x0024180E)],
          stops: [0, .55, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SplashLedgePainter old) => false;
}

class GamePlayScreen extends StatefulWidget {
  final CoinManager coinManager;
  final ui.Image? initialScenery;
  final ui.Image? initialBootDino;

  const GamePlayScreen({
    super.key,
    required this.coinManager,
    this.initialScenery,
    this.initialBootDino,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late final DinoGame _game;

  @override
  void initState() {
    super.initState();
    _game = DinoGame(coinManager: widget.coinManager)..useFlutterResults = true;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => AudioManager.ensureAudioPlaying(),
      child: Scaffold(
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_game.overlays.isActive('SettingsDialog')) {
              _game.overlays.remove('SettingsDialog');
              return;
            }
            if (_game.overlays.isActive('RunResults')) {
              _game.exitToMenu();
              return;
            }
            _game.togglePause();
          },
          child: GameWidget<DinoGame>(
            game: _game,
            loadingBuilder: (_) => SplashArtwork(
              scenery: widget.initialScenery,
              bootDino: widget.initialBootDino,
              ready: true,
              animateEntrance: false,
              progress: 1,
            ),
            overlayBuilderMap: {
              'RunResults': (_, game) => RunResults(game: game),
              'MainMenuOverlay': (BuildContext context, DinoGame game) {
                return MainMenuOverlay(game: game);
              },
              'PauseMenu': (BuildContext context, DinoGame game) {
                return PauseMenu(game: game);
              },
              'SettingsDialog': (BuildContext context, DinoGame game) {
                return SettingsDialog(
                  stage: game.biomeManager.currentStage,
                  onClose: () {
                    game.overlays.remove('SettingsDialog');
                  },
                );
              },
            },
            initialActiveOverlays: const ['MainMenuOverlay'],
            autofocus: true,
          ),
        ),
      ),
    );
  }
}
