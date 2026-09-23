import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import '../../game/biome_manager.dart';
import '../../models/biome.dart';
import '../../managers/audio_manager.dart';

enum _CinematicPhase { none, slideIn, hold, slideOut }
enum _BannerPhase { none, slideIn, hold, slideOut }

class _ScheduledBurst {
  double delay;
  final List<Color> colors;

  _ScheduledBurst({required this.delay, required this.colors});
}

/// MilestoneOverlay renders:
/// 1. Biome-entry letterbox bars & animated era title card with screen flash.
/// 2. Live new-high-score banner under HUD with metallic shimmer sweep.
/// 3. Staggered firework celebrations for score milestones.
///
/// Milestone overlays never cover the ground line or obstacles by more than ~10% of screen height.
/// All timers strictly scale with `globalTimeScale` so they don't drift during hit-stop or slow-mo.
class MilestoneOverlay extends PositionComponent with HasGameReference<DinoGame> {
  final math.Random _rng = math.Random();

  // --- Biome-entry Cinematic State ---
  _CinematicPhase _cinematicPhase = _CinematicPhase.none;
  double _cinematicTimer = 0.0;
  static const double _cinematicSlideDuration = 0.30; // 300 ms ease
  static const double _cinematicHoldDuration = 1.60;  // 1.6 s hold
  Biome? _cinematicBiome;
  int _cinematicStage = 0;
  double _screenFlashAlpha = 0.0;

  // Cached text paints to prevent frame-by-frame text layout rebuilds
  TextPaint? _cinematicTitlePaint;
  TextPaint? _cinematicSubtitlePaint;

  // --- High-Score Banner State ---
  _BannerPhase _bannerPhase = _BannerPhase.none;
  double _bannerTimer = 0.0;
  static const double _bannerSlideDuration = 0.25; // 250 ms slide
  static const double _bannerHoldDuration = 2.0;   // 2.0 s stay
  double _bannerShimmerProgress = 0.0;

  // --- Staggered Firework Bursts ---
  final List<_ScheduledBurst> _scheduledBursts = [];

  // --- Paints & Text Styles ---
  late final Paint _letterboxPaint;
  late final Paint _letterboxBorderPaint;
  late final Paint _flashPaint;
  late final Paint _bannerBgPaint;
  late final Paint _bannerBorderPaint;
  late final TextPaint _bannerTextPaint;

  @override
  Future<void> onLoad() async {
    priority = 990; // High priority: renders on top of world components, just under pause overlay

    _letterboxPaint = Paint()..color = Colors.black;
    _letterboxBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _flashPaint = Paint()..style = PaintingStyle.fill;

    _bannerBgPaint = Paint()..color = const Color(0xEE111827);
    _bannerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFD700);

    _bannerTextPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFE082),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
        shadows: [
          Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 3),
          Shadow(color: Color(0xFFFFB300), offset: Offset(0, 0), blurRadius: 6),
        ],
      ),
    );
  }

  // --- Public API ---

  void _initCinematicTextPaints(Biome biome) {
    _cinematicTitlePaint = TextPaint(
      style: TextStyle(
        color: biome.accentColor,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.2,
        shadows: [
          const Shadow(color: Colors.black, offset: Offset(2, 2)), // Solid drop shadow, no blur
          Shadow(color: biome.accentColor.withValues(alpha: 0.8), offset: Offset.zero, blurRadius: 4), // Reduced blur glow
        ],
      ),
    );

    _cinematicSubtitlePaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.0,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1)), // Solid drop shadow, no blur
        ],
      ),
    );
  }

  /// Trigger the biome-entry cinematic when a biome transition begins.
  void triggerBiomeCinematic(Biome nextBiome, int targetStage) {
    _cinematicBiome = nextBiome;
    _cinematicStage = targetStage;
    _cinematicPhase = _CinematicPhase.slideIn;
    _cinematicTimer = 0.0;
    _screenFlashAlpha = 0.15; // 15% flash

    // FIX: Cache text paints once per transition to avoid heavy GPU blur & layout rebuilds!
    _initCinematicTextPaints(nextBiome);

    // Trigger audio sting & transition particles
    AudioManager.playBiomeSting();
    game.particlePool.emitBiomeTransition(accentColor: nextBiome.accentColor);
  }

  /// Trigger score-milestone celebration fireworks.
  void triggerScoreCelebration({required bool isMajor}) {
    final accent = game.biomeManager.effectiveBiome.accentColor;
    final colors = [
      accent,
      const Color(0xFFFFD700), // Gold
      Colors.white,
      const Color(0xFF4DEEEA), // Cyan
      const Color(0xFFFF4081), // Magenta
    ];

    _scheduledBursts.clear();
    // 2 bursts for normal (1000 score), 4 bursts for major (5000 score)
    final count = isMajor ? 4 : 2;
    for (int i = 0; i < count; i++) {
      _scheduledBursts.add(_ScheduledBurst(
        delay: i * 0.12,
        colors: colors,
      ));
    }
  }

  /// Show the live new-high-score banner under HUD.
  void showHighScoreBanner() {
    _bannerPhase = _BannerPhase.slideIn;
    _bannerTimer = 0.0;
    _bannerShimmerProgress = 0.0;
  }

  /// Reset all milestone state (on game restart, game over, menu).
  void reset() {
    _cinematicPhase = _CinematicPhase.none;
    _cinematicTimer = 0.0;
    _cinematicBiome = null;
    _screenFlashAlpha = 0.0;
    _cinematicTitlePaint = null;
    _cinematicSubtitlePaint = null;
    _bannerPhase = _BannerPhase.none;
    _bannerTimer = 0.0;
    _bannerShimmerProgress = 0.0;
    _scheduledBursts.clear();
  }

  // --- Update Loop ---

  @override
  void update(double dt) {
    // Timers scale with game globalTimeScale to prevent drift during hit-stop or slow-mo
    final scaledDt = dt * game.globalTimeScale;
    super.update(scaledDt);

    if (game.state == GameState.menu || game.state == GameState.gameOver) {
      return;
    }

    _updateCinematic(scaledDt);
    _updateBanner(scaledDt);
    _updateFireworks(scaledDt);
  }

  void _updateCinematic(double dt) {
    if (_cinematicPhase == _CinematicPhase.none) return;

    _cinematicTimer += dt;

    if (_screenFlashAlpha > 0) {
      _screenFlashAlpha = math.max(0.0, _screenFlashAlpha - dt * 0.5);
    }

    switch (_cinematicPhase) {
      case _CinematicPhase.slideIn:
        if (_cinematicTimer >= _cinematicSlideDuration) {
          _cinematicPhase = _CinematicPhase.hold;
          _cinematicTimer = 0.0;
        }
        break;
      case _CinematicPhase.hold:
        if (_cinematicTimer >= _cinematicHoldDuration) {
          _cinematicPhase = _CinematicPhase.slideOut;
          _cinematicTimer = 0.0;
        }
        break;
      case _CinematicPhase.slideOut:
        if (_cinematicTimer >= _cinematicSlideDuration) {
          _cinematicPhase = _CinematicPhase.none;
          _cinematicTimer = 0.0;
          _cinematicBiome = null;
        }
        break;
      case _CinematicPhase.none:
        break;
    }
  }

  void _updateBanner(double dt) {
    if (_bannerPhase == _BannerPhase.none) return;

    _bannerTimer += dt;
    _bannerShimmerProgress = (_bannerShimmerProgress + dt * 1.4) % 2.0;

    switch (_bannerPhase) {
      case _BannerPhase.slideIn:
        if (_bannerTimer >= _bannerSlideDuration) {
          _bannerPhase = _BannerPhase.hold;
          _bannerTimer = 0.0;
        }
        break;
      case _BannerPhase.hold:
        if (_bannerTimer >= _bannerHoldDuration) {
          _bannerPhase = _BannerPhase.slideOut;
          _bannerTimer = 0.0;
        }
        break;
      case _BannerPhase.slideOut:
        if (_bannerTimer >= _bannerSlideDuration) {
          _bannerPhase = _BannerPhase.none;
          _bannerTimer = 0.0;
        }
        break;
      case _BannerPhase.none:
        break;
    }
  }

  void _updateFireworks(double dt) {
    if (_scheduledBursts.isEmpty) return;

    for (int i = _scheduledBursts.length - 1; i >= 0; i--) {
      final burst = _scheduledBursts[i];
      burst.delay -= dt;
      if (burst.delay <= 0) {
        // Upper-third random position
        final sx = game.size.x > 0 ? game.size.x : 800.0;
        final sy = game.size.y > 0 ? game.size.y : 400.0;
        final x = sx * (0.20 + _rng.nextDouble() * 0.60);
        final y = sy * (0.08 + _rng.nextDouble() * 0.22);
        game.particlePool.emitFireworkBurst(Vector2(x, y), colors: burst.colors, count: 24);
        _scheduledBursts.removeAt(i);
      }
    }
  }

  // --- Render Loop ---

  @override
  void render(Canvas canvas) {
    if (game.state == GameState.menu) return;

    // 1. Screen flash during biome entry
    if (_screenFlashAlpha > 0 && _cinematicBiome != null) {
      _flashPaint.color = _cinematicBiome!.accentColor.withValues(alpha: _screenFlashAlpha);
      canvas.drawRect(Rect.fromLTWH(0, 0, game.size.x, game.size.y), _flashPaint);
    }

    // 2. Biome-entry letterbox & title card
    if (_cinematicPhase != _CinematicPhase.none && _cinematicBiome != null) {
      _renderBiomeCinematic(canvas);
    }

    // 3. Live new-high-score banner (hidden in space mode to prevent overlap with space timer bar)
    if (_bannerPhase != _BannerPhase.none && game.state != GameState.spaceMode) {
      _renderHighScoreBanner(canvas);
    }
  }

  void _renderBiomeCinematic(Canvas canvas) {
    final biome = _cinematicBiome!;
    final h = game.size.y;
    final w = game.size.x;

    // Ground line safety constraint:
    // Letterbox bars must never cover ground line or incoming obstacles by more than ~10% of screen height.
    final topBarMax = h * 0.10;
    // Ground surface is at game.ground.groundY
    final groundY = game.ground.groundY;
    final groundHeight = (groundY > 0) ? (h - groundY) : 60.0;
    // Capping bottom bar so at most 5% of screen height is covered above ground line (guaranteed < 10%)
    final bottomBarMax = math.min(h * 0.10, groundHeight + h * 0.05);

    double progress = 0.0;
    double alpha = 1.0;

    switch (_cinematicPhase) {
      case _CinematicPhase.slideIn:
        progress = (_cinematicTimer / _cinematicSlideDuration).clamp(0.0, 1.0);
        progress = Curves.easeOutCubic.transform(progress);
        alpha = progress;
        break;
      case _CinematicPhase.hold:
        progress = 1.0;
        alpha = 1.0;
        break;
      case _CinematicPhase.slideOut:
        progress = 1.0 - (_cinematicTimer / _cinematicSlideDuration).clamp(0.0, 1.0);
        progress = Curves.easeInCubic.transform(progress);
        alpha = progress;
        break;
      case _CinematicPhase.none:
        return;
    }

    final currentTopH = topBarMax * progress;
    final currentBottomH = bottomBarMax * progress;

    // Draw Top Letterbox Bar
    if (currentTopH > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, currentTopH), _letterboxPaint);
      _letterboxBorderPaint.color = biome.accentColor.withValues(alpha: 0.6 * alpha);
      canvas.drawLine(Offset(0, currentTopH), Offset(w, currentTopH), _letterboxBorderPaint);
    }

    // Draw Bottom Letterbox Bar
    if (currentBottomH > 0) {
      final bottomY = h - currentBottomH;
      canvas.drawRect(Rect.fromLTWH(0, bottomY, w, currentBottomH), _letterboxPaint);
      _letterboxBorderPaint.color = biome.accentColor.withValues(alpha: 0.6 * alpha);
      canvas.drawLine(Offset(0, bottomY), Offset(w, bottomY), _letterboxBorderPaint);
    }

    // Title Card Centered in Upper-Mid Canvas (safe from ground & obstacles)
    if (alpha > 0.01) {
      if (_cinematicTitlePaint == null || _cinematicSubtitlePaint == null) {
        _initCinematicTextPaints(biome);
      }

      final cardCenterY = h * 0.38;
      final cardCenterX = w / 2;

      canvas.save();
      final scale = 0.95 + 0.05 * alpha;
      canvas.translate(cardCenterX, cardCenterY);
      canvas.scale(scale, scale);
      canvas.translate(-cardCenterX, -cardCenterY);

      final roman = BiomeManager.toRoman(_cinematicStage + 1);

      // FIX: Use saveLayer to apply alpha efficiently as a single composite pass 
      // instead of rebuilding TextPainters and shadows every frame
      canvas.saveLayer(
        Rect.fromCenter(center: Offset(cardCenterX, cardCenterY), width: w, height: 120),
        Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );

      _cinematicTitlePaint!.render(
        canvas,
        biome.displayName,
        Vector2(cardCenterX, cardCenterY - 14),
        anchor: Anchor.center,
      );

      _cinematicSubtitlePaint!.render(
        canvas,
        '— EPOCH $roman —',
        Vector2(cardCenterX, cardCenterY + 16),
        anchor: Anchor.center,
      );

      canvas.restore(); // Restore saveLayer
      canvas.restore(); // Restore transform
    }
  }

  void _renderHighScoreBanner(Canvas canvas) {
    final w = game.size.x;
    final cx = w / 2;

    const bannerWidth = 240.0;
    const bannerHeight = 28.0;
    const targetY = 78.0; // Under HUD elements, safe from obstacles
    const startY = 36.0;

    double progress = 0.0;
    double alpha = 1.0;

    switch (_bannerPhase) {
      case _BannerPhase.slideIn:
        progress = (_bannerTimer / _bannerSlideDuration).clamp(0.0, 1.0);
        progress = Curves.easeOutBack.transform(progress);
        alpha = progress.clamp(0.0, 1.0);
        break;
      case _BannerPhase.hold:
        progress = 1.0;
        alpha = 1.0;
        break;
      case _BannerPhase.slideOut:
        progress = 1.0 - (_bannerTimer / _bannerSlideDuration).clamp(0.0, 1.0);
        progress = Curves.easeInCubic.transform(progress);
        alpha = progress.clamp(0.0, 1.0);
        break;
      case _BannerPhase.none:
        return;
    }

    final currentY = startY + (targetY - startY) * progress;
    final rect = Rect.fromCenter(
      center: Offset(cx, currentY),
      width: bannerWidth,
      height: bannerHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    canvas.save();
    // Drop shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Dark glassmorphic background
    _bannerBgPaint.color = const Color(0xF0101827).withValues(alpha: alpha);
    canvas.drawRRect(rrect, _bannerBgPaint);

    // Glowing Gold Border
    _bannerBorderPaint.color = const Color(0xFFFFD700).withValues(alpha: alpha);
    canvas.drawRRect(rrect, _bannerBorderPaint);

    // Shimmer sweep reflection
    if (_bannerPhase == _BannerPhase.hold && alpha > 0.5) {
      canvas.save();
      canvas.clipRRect(rrect);
      final shimmerX = rect.left + (rect.width * (_bannerShimmerProgress - 0.5) * 1.6);
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(shimmerX - 30, rect.top, 60, rect.height));
      canvas.drawRect(rect, shimmerPaint);
      canvas.restore();
    }

    // Text: ★ NEW HIGH SCORE! ★
    _bannerTextPaint.render(
      canvas,
      '★ NEW HIGH SCORE! ★',
      Vector2(cx, currentY),
      anchor: Anchor.center,
    );

    canvas.restore();
  }
}
