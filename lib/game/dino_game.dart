import 'desert_journey.dart';
import '../utils/cart_review.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flame/game.dart';
import 'package:flame/events.dart';

import '../components/player.dart';
import '../components/ground.dart';
import '../components/particle.dart';
import '../components/sky_background.dart';
import '../components/ui/hud.dart';
import '../components/ui/combo_display.dart';
import '../components/ui/space_timer_bar.dart';
import '../components/ui/milestone_overlay.dart';
import '../components/ui/start_screen.dart';
import '../components/ui/game_over_screen.dart';
import '../managers/spawn_manager.dart';
import '../managers/speed_manager.dart';
import '../managers/input_manager.dart';
import '../managers/coin_manager.dart';
import '../managers/audio_manager.dart';
import 'biome_manager.dart';
import 'game_state.dart';
import 'run_simulation.dart';
import '../utils/vibration_util.dart';
import '../skins/new_dino_skin.dart';
import '../skins/skin_registry.dart';

enum SpacePhase { none, launch, coinRain, returning }

enum ShakePreset { sideHit, topHit, shieldBreak, rumble, heavyImpact, landing }

class DinoGame extends FlameGame
    with
        HasCollisionDetection,
        TapCallbacks,
        PanDetector,
        KeyboardEvents,
        WidgetsBindingObserver {
  late final Player player;
  late final Ground ground;
  late final SpawnManager spawnManager;
  late final BiomeManager biomeManager;
  late final SpeedManager speedManager;
  late final InputManager inputManager;
  late final ParticlePool particlePool;
  late final ComboDisplay comboDisplay;
  late final CoinManager coinManager;
  late final Hud hud;
  late final MilestoneOverlay milestoneOverlay;

  GameState state = GameState.menu;
  /// Flutter dialogs own navigation and input while the world stays in menu.
  bool menuPanelOpen = false;
  /// Production uses accessible Flutter results; canvas stays for headless tools.
  bool useFlutterResults = false;
  double score = 0;
  double runDistance = 0;
  final DesertJourney desertJourney = DesertJourney();
  bool _desertRun = false;
  int smashedObjects = 0;
  double get difficultyProgress => runDistance * .05;
  final simulation = RunSimulation();
  int combo = 0;
  double comboTimer = 0;
  int frameCount = 0;

  // Milestone tracking
  int _lastCelebratedMilestone = 0;
  int _initialHighScore = 0;
  bool _hasShownHighScoreBannerThisRun = false;

  // Camera Shake / Vibration
  double shakeTimer = 0;
  double shakeIntensity = 0;
  double _shakeDuration = 1.0;
  ShakePreset? currentShakePreset;

  void triggerShake({
    double duration = 1.0,
    double intensity = 5.0,
    ShakePreset preset = ShakePreset.landing,
  }) {
    shakeTimer = duration;
    _shakeDuration = duration;
    shakeIntensity = intensity;
    currentShakePreset = preset;
  }

  // Impact feedback
  double hitStopTimer = 0.0;
  double slowMoTimer = 0.0;

  double get globalTimeScale {
    if (hitStopTimer > 0) return 0;
    if (slowMoTimer > 0) {
      // Lerp from 0.85 back to 1.0
      return 1.0 - (0.15 * (slowMoTimer / 0.20)).clamp(0.0, 0.15);
    }
    return 1.0;
  }

  void triggerHitStop() {
    hitStopTimer = 0.09;
  }

  void triggerNearMissSlowMo() {
    slowMoTimer = 0.20;
  }

  // Space mode
  double spaceTimer = 0;
  static const double spaceLaunchDuration = 2.0;
  static const double spaceCoinDuration = 10.0;
  static const double spaceReturnDuration = 2.8;
  SpacePhase spacePhase = SpacePhase.none;
  double spacePhaseTimer = 0;

  /// 0→1 for darkening sky during launch, 1→0 for lightening during return
  double spaceTransitionProgress = 0;

  DinoGame({required this.coinManager})
    : super(
        camera: CameraComponent(
          viewport: FixedResolutionViewport(resolution: Vector2(640, 360)),
        ),
      ) {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  Vector2 canvasToPlayfield(Vector2 point) =>
      camera.viewport.globalToLocal(point);

  bool tryPauseAt(Vector2 point) {
    if ((state == GameState.playing || state == GameState.spaceMode) &&
        point.x >= size.x / 2 - 30 &&
        point.x <= size.x / 2 + 30 &&
        point.y >= 14 &&
        point.y <= 74) {
      pauseGame();
      return true;
    }
    return false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await NewDinoSkin.preload();
    SkinRegistry.setCosmetics(coinManager.equippedCosmetics.values);

    WidgetsBinding.instance.addObserver(this);

    await AudioManager.init();
    AudioManager.playTitleBgm();

    // Background sky
    world.add(SkyBackground());

    // Core components
    ground = Ground();
    player = Player();
    spawnManager = SpawnManager();
    biomeManager = BiomeManager();
    speedManager = SpeedManager();
    inputManager = InputManager();
    particlePool = ParticlePool();
    comboDisplay = ComboDisplay();

    world.add(ground);
    world.add(player);
    world.add(spawnManager);
    world.add(biomeManager);
    world.add(speedManager);
    world.add(inputManager);
    world.add(particlePool);
    world.add(HighSpeedStreaks());

    // UI
    hud = Hud();
    milestoneOverlay = MilestoneOverlay();
    camera.viewport.add(hud);
    camera.viewport.add(comboDisplay);
    camera.viewport.add(SpaceTimerBar());
    camera.viewport.add(milestoneOverlay);
    camera.viewport.add(StartScreen());
    camera.viewport.add(GameOverScreen());
  }

  @override
  void onRemove() {
    unawaited(coinManager.forceSave());
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // App moved to background — pause gameplay & completely silence music audio!
      if (this.state == GameState.playing ||
          this.state == GameState.spaceMode) {
        pauseGame();
      }
      AudioManager.pauseBgm();
      unawaited(coinManager.forceSave());
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground
      if (this.state == GameState.paused) {
        // Keep game safely paused on Pause Menu so player doesn't unpause unannounced
        AudioManager.pauseBgm();
      } else if (this.state == GameState.menu) {
        AudioManager.playTitleBgm();
      } else if (this.state == GameState.playing ||
          this.state == GameState.spaceMode) {
        AudioManager.resumeBgm();
      }
    }
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (this.state == GameState.playing ||
          this.state == GameState.spaceMode) {
        pauseGame();
      }
      AudioManager.pauseBgm();
    }
  }

  final math.Random _rng = math.Random();

  @override
  void update(double dt) {
    if (state == GameState.paused) return;
    simulation.advance(dt, (realDt) {
      final simulationDt = realDt * globalTimeScale;
      super.update(simulationDt);
      _simulateStep(realDt, simulationDt);
    });
  }

  void _simulateStep(double realDt, double clampedDt) {
    frameCount++;

    if (hitStopTimer > 0) hitStopTimer -= realDt;
    if (slowMoTimer > 0) slowMoTimer -= realDt;

    // Safety against stuck time-scale in non-playing states
    if (state != GameState.playing && state != GameState.spaceMode) {
      hitStopTimer = 0;
      slowMoTimer = 0;
    }

    if (shakeTimer > 0) {
      shakeTimer -= realDt;
      if (shakeTimer <= 0) {
        shakeTimer = 0;
        camera.viewfinder.position = Vector2.zero();
      } else {
        // Exponential decay so shakes settle smoothly
        final decay = math.exp(-2.0 * (1.0 - (shakeTimer / _shakeDuration)));
        final currentIntensity = shakeIntensity * decay;

        double dx = 0;
        double dy = 0;

        switch (currentShakePreset) {
          case ShakePreset.sideHit:
            dx = (_rng.nextDouble() > 0.5 ? 1 : -1) * currentIntensity;
            dy = (_rng.nextDouble() - 0.5) * currentIntensity * 0.5;
            break;
          case ShakePreset.topHit:
            dx = (_rng.nextDouble() - 0.5) * currentIntensity * 0.5;
            dy = (_rng.nextDouble() > 0.5 ? 1 : -1) * currentIntensity;
            break;
          case ShakePreset.shieldBreak:
            // High frequency, low amplitude
            dx = math.sin(frameCount * 1.5) * currentIntensity;
            dy = math.cos(frameCount * 1.5) * currentIntensity;
            break;
          case ShakePreset.rumble:
            // Low frequency
            dx = math.sin(frameCount * 0.2) * currentIntensity;
            dy = math.cos(frameCount * 0.2) * currentIntensity;
            break;
          case ShakePreset.heavyImpact:
          case ShakePreset.landing:
          default:
            dx = (_rng.nextDouble() - 0.5) * currentIntensity * 2;
            dy = (_rng.nextDouble() - 0.5) * currentIntensity * 2;
            break;
        }

        camera.viewfinder.position = Vector2(dx, dy);
      }
    }

    switch (state) {
      case GameState.playing:
        _updatePlaying(clampedDt);
        break;
      case GameState.spaceMode:
        _updateSpaceMode(clampedDt);
        break;
      case GameState.gameOver:
        break;
      case GameState.menu:
        break;
      case GameState.paused:
        break;
    }
  }

  void _checkMilestones() {
    final currentMilestone = (score / 1000).floor();
    if (currentMilestone > _lastCelebratedMilestone) {
      // Correction 1: If multiple 1000-boundaries passed in a single frame, celebrate ONLY the latest one
      final isMajor = (currentMilestone % 5 == 0);
      milestoneOverlay.triggerScoreCelebration(isMajor: isMajor);
      hud.triggerScorePop(isMajor: isMajor);
      AudioManager.playMilestoneChime();
      _lastCelebratedMilestone = currentMilestone;
    }
  }

  void _checkHighScoreBanner() {
    // Correction 2: Only check and trigger while in playing state (never during spaceMode)
    if (state == GameState.playing) {
      if (!_hasShownHighScoreBannerThisRun &&
          _initialHighScore > 0 &&
          score > _initialHighScore) {
        _hasShownHighScoreBannerThisRun = true;
        milestoneOverlay.showHighScoreBanner();
      }
    }
  }

  void _updatePlaying(double dt) {
    runDistance += speedManager.currentSpeed * dt;
    score += speedManager.currentSpeed * dt * 0.05;
    if (desertJourney.active) {
      speedManager.currentSpeed = DesertJourney.speed;
      if (runDistance >= DesertJourney.length) {
        desertJourney.completed = true;
        desertJourney.active = false;
        spawnManager.resumeGroundSpawning();
        AudioManager.playMilestoneChime();
        return;
      }
    } else {
      speedManager.updateSpeed(difficultyProgress);
      biomeManager.updateBiome(difficultyProgress, speedManager.currentSpeed);
    }
    _checkMilestones();
    _checkHighScoreBanner();

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        if (combo > 0) {
          comboDisplay.showComboBreak(combo);
        }
        combo = 0;
      }
    }
  }

  void _updateSpaceMode(double dt) {
    final cosmicBonus = 1.0 + (coinManager.cosmicLevel * 0.4);
    score += dt * 5 * cosmicBonus;
    _checkMilestones();
    // High-score banner check intentionally deferred until returning to playing state!
    spacePhaseTimer -= dt;

    switch (spacePhase) {
      case SpacePhase.launch:
        // Darken sky 0→1 over launch duration
        spaceTransitionProgress = (1.0 - spacePhaseTimer / spaceLaunchDuration)
            .clamp(0.0, 1.0);
        if (spacePhaseTimer <= 0) {
          spacePhase = SpacePhase.coinRain;
          spacePhaseTimer = spaceCoinDuration;
          spaceTimer = spaceCoinDuration; // for timer bar
          spaceTransitionProgress = 1.0;
        }
        break;
      case SpacePhase.coinRain:
        spaceTimer = spacePhaseTimer; // keep in sync for bar
        spaceTransitionProgress = 1.0;
        if (spacePhaseTimer <= 0) {
          spacePhase = SpacePhase.returning;
          spacePhaseTimer = spaceReturnDuration;
          spawnManager.clearGroundEntities(); // remove remaining coins
        }
        break;
      case SpacePhase.returning:
        // Lighten sky 1→0 over return duration
        spaceTransitionProgress = (spacePhaseTimer / spaceReturnDuration).clamp(
          0.0,
          1.0,
        );
        if (spacePhaseTimer <= 0) {
          _finishExitSpaceMode();
        }
        break;
      case SpacePhase.none:
        break;
    }
  }

  void enterSpaceMode() {
    state = GameState.spaceMode;
    spacePhase = SpacePhase.launch;
    spacePhaseTimer = spaceLaunchDuration;
    spaceTransitionProgress = 0;
    spaceTimer = 0; // timer bar hidden during launch
    player.enterSpaceMode();
    spawnManager.clearGroundEntities();
    particlePool.emitGravityLaunch(player.position);
  }

  /// Called when returning phase ends — snap back to playing with heroic landing impact!
  void _finishExitSpaceMode() {
    state = GameState.playing;
    overlays.remove('RunResults');
    spacePhase = SpacePhase.none;
    spaceTransitionProgress = 0;
    spaceTimer = 0;
    spawnManager.clearGroundEntities();
    spawnManager.clearMeteors();
    player.exitSpaceMode();
    spawnManager.resumeGroundSpawning();
    final shieldLvl = coinManager.shieldLevel;
    player.invincibleTimer = 3.0 + (shieldLvl * 0.5);

    // Hero touchdown effects on path
    final footPos = Vector2(
      player.position.x + (player.size.x * player.scale.x) * 0.45,
      player.position.y + player.size.y * player.scale.y,
    );
    final currentBiome = biomeManager.effectiveBiome.name;
    if (currentBiome == 'DESERT') {
      particlePool.emitDesertLandingImpact(footPos);
    } else {
      particlePool.emitJumpDust(footPos);
    }
    triggerShake(duration: 0.25, intensity: 5.0);
    GameVibration.heavyImpact();
  }

  void startGame({
    int? startingStage,
    bool keepMenuOverlay = false,
    bool? authoredDesert,
  }) {
    state = GameState.playing;
    if (!keepMenuOverlay) overlays.remove('MainMenuOverlay');
    overlays.remove('PauseMenu');
    overlays.remove('SettingsDialog');
    score = 0;
    runDistance = 0;
    smashedObjects = 0;
    // An explicit request can replay the authored route for review tooling.
    // Ordinary Retry never repeats onboarding once it has been introduced.
    _desertRun = authoredDesert ?? (_desertRun && !coinManager.hasSeenTutorial);
    desertJourney.reset();
    simulation.reset();
    hitStopTimer = 0;
    slowMoTimer = 0;
    shakeTimer = 0;
    camera.viewfinder.position = Vector2.zero();
    _stateBeforePause = null;
    resumeEngine();
    combo = 0;
    comboTimer = 0;
    spaceTimer = 0;
    spacePhase = SpacePhase.none;
    spacePhaseTimer = 0;
    spaceTransitionProgress = 0;
    _lastCelebratedMilestone = 0;
    _initialHighScore = coinManager.highScore;
    _hasShownHighScoreBannerThisRun = false;
    milestoneOverlay.reset();
    coinManager.resetRunCoins();
    speedManager.reset();
    biomeManager.reset(
      startingStage: startingStage ?? biomeManager.currentStage,
    );
    ground.resetSurface();
    player.reset();
    spawnManager.reset();
    particlePool.clear();
    if (state == GameState.playing && cartReviewRequested) {
      biomeManager.currentStage = 0;
      spawnManager.startCartLane();
    } else if (_desertRun && biomeManager.currentStage == 0) {
      desertJourney.start();
      unawaited(coinManager.markTutorialSeen());
    }
    AudioManager.playGameplayBgm();
  }

  void reviveGame() {
    overlays.remove('RunResults');
    overlays.remove('MainMenuOverlay');
    overlays.remove('PauseMenu');
    overlays.remove('SettingsDialog');
    ground.resetSurface();
    player.revive();
    spawnManager.clearGroundEntities();
    spawnManager.clearMeteors();
    spawnManager.resumeGroundSpawning();

    // FIX: Clear space phase timers if the player died during a rocket flight!
    spacePhase = SpacePhase.none;
    spaceTimer = 0;
    spacePhaseTimer = 0;
    spaceTransitionProgress = 0;

    state = GameState.playing;
    resumeEngine();
    triggerHitStop();
    AudioManager.playGameplayBgm();
  }

  void gameOver() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    coinManager.updateHighScore(score.toInt());
    unawaited(coinManager.forceSave());
    AudioManager.playGameOverBgm();
    if (useFlutterResults) overlays.add('RunResults');
  }

  GameState? _stateBeforePause;

  void pauseGame() {
    if (state == GameState.playing || state == GameState.spaceMode) {
      _stateBeforePause = state;
      state = GameState.paused;
      overlays.add('PauseMenu');
      AudioManager.pauseBgm();
      unawaited(coinManager.forceSave());
      pauseEngine();
    }
  }

  void resumeGame() {
    if (state == GameState.paused) {
      state = _stateBeforePause ?? GameState.playing;
      _stateBeforePause = null;
      overlays.remove('PauseMenu');
      AudioManager.resumeBgm();
      resumeEngine();
    }
  }

  void togglePause() {
    if (state == GameState.paused) {
      resumeGame();
    } else if (state == GameState.playing || state == GameState.spaceMode) {
      pauseGame();
    }
  }

  void exitToMenu() {
    overlays.remove('RunResults');
    final selectedStage = biomeManager.currentStage;
    _desertRun = false;
    desertJourney.reset();
    unawaited(coinManager.forceSave());
    spacePhase = SpacePhase.none;
    spaceTimer = 0;
    spacePhaseTimer = 0;
    spaceTransitionProgress = 0;
    _stateBeforePause = null;
    state = GameState.menu;
    overlays.remove('PauseMenu');
    overlays.remove('SettingsDialog');
    overlays.add('MainMenuOverlay');
    resumeEngine();
    milestoneOverlay.reset();
    speedManager.reset();
    biomeManager.reset(startingStage: selectedStage);
    ground.resetSurface();
    player.reset();
    spawnManager.reset();
    particlePool.clear();
    AudioManager.playTitleBgm();
  }

  bool handleResultsTap(Vector2 point) {
    if (state != GameState.gameOver) return false;
    final cx = size.x / 2, cy = size.y / 2;
    if ((point.y - (cy + 70)).abs() > 27) return false;
    if ((point.x - (cx - 116)).abs() <= 54) {
      startGame();
      return true;
    }
    if ((point.x - cx).abs() <= 54) {
      exitToMenu();
      return true;
    }
    if ((point.x - (cx + 116)).abs() <= 54) {
      reviveGame();
      return true;
    }
    return false;
  }

  // --- Input handling ---

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (menuPanelOpen || overlays.isActive('MainMenuOverlay') ||
        overlays.isActive('SettingsDialog') || overlays.isActive('RunResults')) {
      return;
    }

    // Check for pause button tap (bulletproof canvasPosition + localPosition check centered around cy = 44)
    final point = canvasToPlayfield(event.canvasPosition);
    if (tryPauseAt(point)) return;

    // Ensure web browser audio context is active on gesture
    AudioManager.ensureAudioPlaying();

    if (state == GameState.menu) {
      AudioManager.playTitleBgm();
      // Menu overlay handles its own taps; do not fall through to _handleInputStart() / startGame()
      return;
    }

    if (state == GameState.gameOver) {
      handleResultsTap(point);
      return;
    }

    _handleInputStart();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _handleInputEnd();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    _handleInputEnd();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (state == GameState.spaceMode) {
      // Horizontal + vertical drag for mobile coin collection
      final scale = (camera.viewport as FixedResolutionViewport).scale;
      player.targetX += info.delta.global.x / scale.x;
      player.position.y += info.delta.global.y / scale.y;
      // Clamp to screen
      player.position.y = player.position.y.clamp(
        0,
        size.y - player.size.y * player.scale.y - 20,
      );
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (menuPanelOpen || overlays.isActive('MainMenuOverlay') ||
        overlays.isActive('SettingsDialog') || overlays.isActive('RunResults')) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        togglePause();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _handleInputStart();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        player.movingLeft = true;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.movingRight = true;
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _handleInputEnd();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        player.movingLeft = false;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.movingRight = false;
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _handleInputStart() {
    switch (state) {
      case GameState.menu:
      case GameState.gameOver:
        startGame();
        break;
      case GameState.playing:
        player.jump();
        break;
      case GameState.spaceMode:
        player.isThrusting = true;
        break;
      case GameState.paused:
        break;
    }
  }

  void _handleInputEnd() {
    if (state == GameState.spaceMode) {
      player.isThrusting = false;
    } else if (state == GameState.playing) {
      player.onJumpRelease();
    }
  }
}
