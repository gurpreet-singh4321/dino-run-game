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
import '../../skins/skin.dart';
import '../../skins/skin_registry.dart';
import '../../utils/scenery_cache.dart';
import '../../utils/boot_handoff.dart';
import '../../utils/boot_preview_cache.dart';
import 'animated_dino_preview.dart';
import 'dino_hill_top.dart';
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
    with TickerProviderStateMixin {
  int completed = 0;
  bool ready = false;
  bool _handedOff = false;
  bool _gameMounted = false;
  bool _flightActive = false;
  bool _handoffDone = false;
  ui.Image? scenery;
  ui.Image? bootDino;
  CharacterSkin? _splashSkin;
  String? error;
  static const total = 8;
  final GlobalKey _rootKey = GlobalKey();
  final GlobalKey _splashDinoKey = GlobalKey();
  final GlobalKey _menuDinoKey = GlobalKey();
  Rect? _fromRect;
  Rect? _toRect;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: 0.42,
  );
  late final AnimationController _handoff = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _handoffDone = true;
          _flightActive = false;
        });
      }
    });

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _handoff.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _step() {
    if (!mounted) return;
    setState(() => completed++);
    final target = (0.42 + 0.58 * (completed / total)).clamp(0.42, 1.0);
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

  Rect? _measureLocalRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final root = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || root == null || !box.hasSize || !root.hasSize) {
      return null;
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: root);
    return topLeft & box.size;
  }

  void _onMenuReady() {
    if (!mounted || _flightActive || _handoffDone) return;
    _toRect = _measureLocalRect(_menuDinoKey);
    if (MediaQuery.disableAnimationsOf(context) ||
        _fromRect == null ||
        _toRect == null ||
        _splashSkin == null) {
      setState(() {
        _handoffDone = true;
        _flightActive = false;
      });
      return;
    }
    setState(() => _flightActive = true);
    _handoff.forward(from: 0);
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
    _progress.value = 0.42;
    try {
      // Decode desert backdrop and Dino rig first so the HTML handoff reveals
      // the live clothed Dino on the same epoch hilltop with zero naked pop-in.
      try {
        final results = await Future.wait<Object?>([
          SceneryCache.load(SceneryCache.paths.first),
          _loadBootDino(),
          NewDinoSkin.preload(),
        ]);
        SkinRegistry.setCosmetics(widget.coinManager.equippedCosmetics.values);
        final skin = SkinRegistry.createInstance(SkinRegistry.defaultSkin.id)
          ..cosmetics = List.of(SkinRegistry.defaultSkin.cosmetics);
        unawaited(cacheBootStagePreview(skin));
        if (mounted) {
          setState(() {
            scenery = results[0] as ui.Image?;
            bootDino = results[1] as ui.Image?;
            _splashSkin = skin;
            ready = true;
          });
        }
      } catch (_) {}
      if (!mounted) return;
      _step();
      _completeWebHandoff();

      await Future.wait([
        GearAssets.preload().then((_) => _step()),
        NewDinoSkin.preload().then((_) {
          if (_splashSkin == null) {
            SkinRegistry.setCosmetics(
              widget.coinManager.equippedCosmetics.values,
            );
            final skin = SkinRegistry.createInstance(SkinRegistry.defaultSkin.id)
              ..cosmetics = List.of(SkinRegistry.defaultSkin.cosmetics);
            if (mounted) {
              setState(() {
                _splashSkin = skin;
                ready = true;
              });
            }
          }
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
      await precacheImage(
        EpochScenery.imageFor(0),
        context,
      ).catchError((Object _) {});
      if (!mounted) return;
      await _progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      _fromRect = _measureLocalRect(_splashDinoKey);
      setState(() => _gameMounted = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Dino could not load. Try again.');
        _completeWebHandoff();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: _rootKey,
    children: [
      if (_gameMounted)
        GamePlayScreen(
          coinManager: widget.coinManager,
          initialScenery: scenery,
          initialBootDino: bootDino,
          menuDinoKey: _menuDinoKey,
          showMenuDino: _handoffDone,
          onMenuReady: _onMenuReady,
          embeddedLoading: true,
        ),
      if (!_handoffDone)
        AnimatedBuilder(
          animation: Listenable.merge([_progress, _handoff]),
          builder: (context, _) {
            final t = _flightActive ? _handoff.value : 0.0;
            final splashFade = _flightActive
                ? (1.0 - Curves.easeOut.transform((t * 1.85).clamp(0.0, 1.0)))
                : 1.0;
            final glideT = _flightActive
                ? Curves.easeInOutCubic.transform(t)
                : 0.0;
            final rect = (_flightActive && _fromRect != null && _toRect != null)
                ? Rect.lerp(_fromRect, _toRect, glideT)
                : null;
            return Stack(
              children: [
                if (splashFade > 0.001)
                  Opacity(
                    opacity: splashFade,
                    child: SplashArtwork(
                      scenery: scenery,
                      bootDino: bootDino,
                      skin: _splashSkin,
                      dinoStageKey: _splashDinoKey,
                      showDinoStage: !_flightActive,
                      ready: ready,
                      animateEntrance: false,
                      progress: _progress.value,
                      error: error,
                      onRetry: _load,
                    ),
                  ),
                if (rect != null && _splashSkin != null)
                  Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                      child: _SplashHillAndDino(
                        skin: _splashSkin!,
                        width: rect.width,
                        height: rect.height,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
    ],
  );
}

class _SplashHillAndDino extends StatelessWidget {
  final CharacterSkin skin;
  final double width;
  final double height;
  const _SplashHillAndDino({
    required this.skin,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ledgeHeight = (height * .26).clamp(24.0, 86.0);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: -ledgeHeight * .50,
            width: width * 1.54,
            height: ledgeHeight,
            child: const RepaintBoundary(
              child: CustomPaint(painter: DinoHillTopPainter(0)),
            ),
          ),
          Positioned.fill(
            child: AnimatedDinoPreview(template: skin),
          ),
        ],
      ),
    );
  }
}

/// The real loading screen, separately renderable for compact-device review.
class SplashArtwork extends StatefulWidget {
  final ui.Image? scenery;
  final ui.Image? bootDino;
  final CharacterSkin? skin;
  final GlobalKey? dinoStageKey;
  final bool showDinoStage;
  final bool ready, animateEntrance;
  final double progress;
  final String? error;
  final VoidCallback? onRetry;
  const SplashArtwork({
    super.key,
    this.scenery,
    this.bootDino,
    this.skin,
    this.dinoStageKey,
    this.showDinoStage = true,
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
                          final dinoHeight = small ? 116.0 : (portrait ? 136.0 : 196.0);
                          final dinoWidth = dinoHeight * .86;
                          final ledgeHeight = (dinoHeight * .26).clamp(24.0, 62.0);
                          final dinoStage = Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              key: widget.dinoStageKey,
                              height: dinoHeight,
                              width: dinoWidth,
                              child: Visibility(
                                visible: widget.showDinoStage,
                                maintainState: true,
                                maintainAnimation: true,
                                maintainSize: true,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Positioned(
                                      bottom: -ledgeHeight * .50,
                                      width: dinoWidth * 1.54,
                                      height: ledgeHeight,
                                      child: const RepaintBoundary(
                                        child: CustomPaint(
                                          painter: DinoHillTopPainter(0),
                                        ),
                                      ),
                                    ),
                                    if (widget.skin != null)
                                      Positioned.fill(
                                        child: AnimatedDinoPreview(
                                          template: widget.skin!,
                                        ),
                                      )
                                    else
                                      Positioned.fill(
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
                            ),
                          );
                          final lockCardHeight =
                              widget.error == null &&
                              MediaQuery.textScalerOf(context).scale(1.0) <= 1.05;
                          final card = SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: small ? 48.0 : 66.0,
                                  child: CustomPaint(
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
                                        small ? 6 : 8,
                                        small ? 18 : 24,
                                        small ? 10 : 12,
                                      ),
                                      child: Center(
                                        widthFactor: 1,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontSize: small ? 26 : 36,
                                                height: 1.1,
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
                                  ),
                                ),
                                SizedBox(height: small ? 8 : 12),
                                SizedBox(
                                  height: lockCardHeight
                                      ? (small ? 92.0 : 114.0)
                                      : null,
                                  child: MenuPaper(
                                    accent: MenuPalette.gold,
                                    padding: EdgeInsets.fromLTRB(
                                      small ? 14 : 18,
                                      small ? 10 : 14,
                                      small ? 14 : 18,
                                      small ? 12 : 16,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Adventure awaits.',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: small ? 15 : 17,
                                            height: (small ? 18 : 20) / (small ? 15 : 17),
                                            fontWeight: FontWeight.w700,
                                            color: MenuPalette.ink,
                                          ),
                                        ),
                                        SizedBox(height: small ? 8 : 11),
                                        SizedBox(
                                          height: small ? 15 : 18,
                                          child: Container(
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
                                                minHeight: small ? 7 : 10,
                                                color: MenuPalette.gold,
                                                backgroundColor: const Color(0xFF2B3E58),
                                              ),
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
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            color: widget.error != null
                                                ? MenuPalette.red
                                                : MenuPalette.muted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: small ? 12 : 13,
                                            height: (small ? 14 : 17) / (small ? 12 : 13),
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

class GamePlayScreen extends StatefulWidget {
  final CoinManager coinManager;
  final ui.Image? initialScenery;
  final ui.Image? initialBootDino;
  final GlobalKey? menuDinoKey;
  final bool showMenuDino;
  final VoidCallback? onMenuReady;
  final bool embeddedLoading;

  const GamePlayScreen({
    super.key,
    required this.coinManager,
    this.initialScenery,
    this.initialBootDino,
    this.menuDinoKey,
    this.showMenuDino = true,
    this.onMenuReady,
    this.embeddedLoading = false,
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
            loadingBuilder: (_) => widget.embeddedLoading
                ? const SizedBox.shrink()
                : SplashArtwork(
                    scenery: widget.initialScenery,
                    bootDino: widget.initialBootDino,
                    ready: true,
                    animateEntrance: false,
                    progress: 1,
                  ),
            overlayBuilderMap: {
              'RunResults': (_, game) => RunResults(game: game),
              'MainMenuOverlay': (BuildContext context, DinoGame game) {
                return MainMenuOverlay(
                  game: game,
                  dinoStageKey: widget.menuDinoKey,
                  showDino: widget.showMenuDino,
                  onMenuReady: widget.onMenuReady,
                );
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
