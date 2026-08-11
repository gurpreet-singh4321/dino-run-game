import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';

import '../components/player.dart';
import '../components/ground.dart';
import '../components/particle.dart';
import '../components/sky_background.dart';
import '../components/ui/hud.dart';
import '../components/ui/combo_display.dart';
import '../components/ui/space_timer_bar.dart';
import '../components/ui/start_screen.dart';
import '../components/ui/game_over_screen.dart';
import '../managers/spawn_manager.dart';
import '../managers/speed_manager.dart';
import '../managers/input_manager.dart';
import '../managers/coin_manager.dart';
import '../managers/audio_manager.dart';
import 'biome_manager.dart';
import 'game_state.dart';

enum SpacePhase { none, launch, coinRain, returning }

class DinoGame extends FlameGame with HasCollisionDetection, TapCallbacks, PanDetector, KeyboardEvents, WidgetsBindingObserver {
  late final Player player;
  late final Ground ground;
  late final SpawnManager spawnManager;
  late final BiomeManager biomeManager;
  late final SpeedManager speedManager;
  late final InputManager inputManager;
  late final ParticlePool particlePool;
  late final ComboDisplay comboDisplay;
  late final CoinManager coinManager;

  GameState state = GameState.menu;
  double score = 0;
  int combo = 0;
  double comboTimer = 0;
  int frameCount = 0;

  // Camera Shake / Vibration
  double shakeTimer = 0;
  double shakeIntensity = 0;

  void triggerShake({double duration = 1.0, double intensity = 5.0}) {
    shakeTimer = duration;
    shakeIntensity = intensity;
  }

  // Space mode
  double spaceTimer = 0;
  static const double spaceLaunchDuration = 2.0;
  static const double spaceCoinDuration = 10.0;
  static const double spaceReturnDuration = 2.5;
  SpacePhase spacePhase = SpacePhase.none;
  double spacePhaseTimer = 0;
  /// 0→1 for darkening sky during launch, 1→0 for lightening during return
  double spaceTransitionProgress = 0;

  DinoGame({required this.coinManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    WidgetsBinding.instance.addObserver(this);

    await AudioManager.init();
    AudioManager.playTitleBgm();

    // Preload images
    await Flame.images.load('dino_sprite.png');

    // Background sky
    add(SkyBackground());

    // Core components
    ground = Ground();
    player = Player();
    spawnManager = SpawnManager();
    biomeManager = BiomeManager();
    speedManager = SpeedManager();
    inputManager = InputManager();
    particlePool = ParticlePool();
    comboDisplay = ComboDisplay();

    add(ground);
    add(player);
    add(spawnManager);
    add(biomeManager);
    add(speedManager);
    add(inputManager);
    add(particlePool);

    // UI
    add(Hud());
    add(comboDisplay);
    add(SpaceTimerBar());
    add(StartScreen());
    add(GameOverScreen());
  }

  @override
  void onRemove() {
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
      if (this.state == GameState.playing || this.state == GameState.spaceMode) {
        pauseGame();
      }
      AudioManager.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground
      if (this.state == GameState.paused) {
        // Keep game safely paused on Pause Menu so player doesn't unpause unannounced
        AudioManager.pauseBgm();
      } else if (this.state == GameState.menu) {
        AudioManager.playTitleBgm();
      } else if (this.state == GameState.playing || this.state == GameState.spaceMode) {
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
      if (this.state == GameState.playing || this.state == GameState.spaceMode) {
        pauseGame();
      }
      AudioManager.pauseBgm();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    frameCount++;

    if (shakeTimer > 0) {
      shakeTimer -= dt;
      if (shakeTimer <= 0) {
        shakeTimer = 0;
        camera.viewfinder.position = Vector2.zero();
      } else {
        final rng = math.Random();
        final dx = (rng.nextDouble() - 0.5) * shakeIntensity * 2;
        final dy = (rng.nextDouble() - 0.5) * shakeIntensity * 2;
        camera.viewfinder.position = Vector2(dx, dy);
      }
    }

    switch (state) {
      case GameState.playing:
        _updatePlaying(dt);
        break;
      case GameState.spaceMode:
        _updateSpaceMode(dt);
        break;
      case GameState.gameOver:
        break;
      case GameState.menu:
        break;
      case GameState.paused:
        break;
    }
  }

  void _updatePlaying(double dt) {
    score += speedManager.currentSpeed * dt * 0.05;
    speedManager.updateSpeed(score);
    biomeManager.updateBiome(score, speedManager.currentSpeed);

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        combo = 0;
        comboDisplay.hide();
      }
    }
  }

  void _updateSpaceMode(double dt) {
    score += dt * 5;
    spacePhaseTimer -= dt;

    switch (spacePhase) {
      case SpacePhase.launch:
        // Darken sky 0→1 over launch duration
        spaceTransitionProgress = (1.0 - spacePhaseTimer / spaceLaunchDuration).clamp(0.0, 1.0);
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
        spaceTransitionProgress = (spacePhaseTimer / spaceReturnDuration).clamp(0.0, 1.0);
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

  /// Called when returning phase ends — snap back to playing
  void _finishExitSpaceMode() {
    state = GameState.playing;
    spacePhase = SpacePhase.none;
    spaceTransitionProgress = 0;
    spaceTimer = 0;
    spawnManager.clearGroundEntities();
    player.exitSpaceMode();
    spawnManager.resumeGroundSpawning();
    player.invincibleTimer = 3.0;
  }

  void startGame() {
    state = GameState.playing;
    score = 0;
    combo = 0;
    comboTimer = 0;
    spaceTimer = 0;
    spacePhase = SpacePhase.none;
    spacePhaseTimer = 0;
    spaceTransitionProgress = 0;
    coinManager.resetRunCoins();
    speedManager.reset();
    biomeManager.reset();
    player.reset();
    spawnManager.reset();
    AudioManager.playGameplayBgm();
  }

  void reviveGame() {
    player.revive();
    spawnManager.clearGroundEntities();
    state = GameState.playing;
    resumeEngine();
    AudioManager.playGameplayBgm();
  }

  void gameOver() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    coinManager.updateHighScore(score.toInt());
    AudioManager.playGameOverBgm();
  }

  GameState? _stateBeforePause;

  void pauseGame() {
    if (state == GameState.playing || state == GameState.spaceMode) {
      _stateBeforePause = state;
      state = GameState.paused;
      overlays.add('PauseMenu');
      AudioManager.pauseBgm();
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
    state = GameState.menu;
    overlays.remove('PauseMenu');
    resumeEngine();
    speedManager.reset();
    biomeManager.reset();
    player.reset();
    spawnManager.reset();
    AudioManager.playTitleBgm();
  }

  // --- Input handling ---

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    
    // Check for pause button tap (bulletproof canvasPosition + localPosition check centered around cy = 44)
    if (state == GameState.playing) {
      final cx = size.x / 2;
      final canvasX = event.canvasPosition.x;
      final canvasY = event.canvasPosition.y;
      final localX = event.localPosition.x;
      final localY = event.localPosition.y;

      final isCanvasHit = (canvasX > cx - 60 && canvasX < cx + 60 && canvasY >= 0 && canvasY <= 100);
      final isLocalHit = (localX > cx - 60 && localX < cx + 60 && localY >= 0 && localY <= 100);

      if (isCanvasHit || isLocalHit) {
        pauseGame();
        return;
      }
    }

    // Ensure web browser audio context is active on gesture
    AudioManager.ensureAudioPlaying();

    if (state == GameState.menu) {
      AudioManager.playTitleBgm();
      // Check if tap hit top-right Settings button on menu
      if (event.canvasPosition.x > size.x - 140 && event.canvasPosition.y < 60) {
        overlays.add('SettingsDialog');
        return;
      }
    }

    if (state == GameState.gameOver) {
      final cx = size.x / 2;
      final cy = size.y / 2;
      final tx = event.canvasPosition.x;
      final ty = event.canvasPosition.y;

      // 1. REVIVE BUTTON HIT-TEST (centered at cy + 20, height 44, width 230)
      if (tx >= cx - 120 && tx <= cx + 120 && ty >= cy - 5 && ty <= cy + 45) {
        reviveGame();
        return;
      }

      // 2. CONTINUE TEXT HIT-TEST (centered at cy + 94, height 32, width 160)
      if (tx >= cx - 100 && tx <= cx + 100 && ty >= cy + 75 && ty <= cy + 115) {
        startGame();
        return;
      }

      // Block taps anywhere else on Game Over screen so it doesn't trigger unwanted jumps or restarts!
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
      player.targetX += info.delta.global.x;
      player.position.y += info.delta.global.y;
      // Clamp to screen
      player.position.y = player.position.y.clamp(0, size.y - player.size.y * player.scale.y - 20);
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
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
    }
  }
}
