import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../models/biome.dart';
import 'dino_game.dart';

class BiomeManager extends Component with HasGameReference<DinoGame> {
  int currentStage = 0;
  double progress = 0.0;
  bool isTransitioning = false;

  // Biome score threshold (4500 score points per biome = ~3 - 4 minutes of gameplay)
  static const double biomeScoreInterval = 4500.0;
  static const double transitionDurationSeconds = 3.5;

  static const List<Biome> biomes = [
    Biome(
      name: 'DESERT',
      skyTop: Color(0xFF184988),
      skyBottom: Color(0xFFEAA63F),
      groundTop: Color(0xFFE5B25D),
      groundBottom: Color(0xFF7A4515),
    ),
    Biome(
      name: 'RAIN',
      skyTop: Color(0xFF1E3342),
      skyBottom: Color(0xFF4B6B7C),
      groundTop: Color(0xFF35483E),
      groundBottom: Color(0xFF1A2621),
    ),
    Biome(
      name: 'FOREST',
      skyTop: Color(0xFF4CAF50),
      skyBottom: Color(0xFF81C784),
      groundTop: Color(0xFF4CAF50),
      groundBottom: Color(0xFF2E7D32),
    ),
    Biome(
      name: 'ICE',
      skyTop: Color(0xFFB3E5FC),
      skyBottom: Color(0xFFE1F5FE),
      groundTop: Color(0xFFE0F7FA),
      groundBottom: Color(0xFFB3E5FC),
    ),
    Biome(
      name: 'VOLCANO',
      skyTop: Color(0xFF3E2723),
      skyBottom: Color(0xFFFF7043),
      groundTop: Color(0xFF3E2723),
      groundBottom: Color(0xFF1B0000),
    ),
    Biome(
      name: 'COSMOS',
      skyTop: Color(0xFF0D0021),
      skyBottom: Color(0xFF1A0033),
      groundTop: Color(0xFF311B92),
      groundBottom: Color(0xFF1A0033),
    ),
  ];

  @override
  void update(double dt) {
    super.update(dt);

    if (isTransitioning) {
      progress += dt / transitionDurationSeconds;
      if (progress >= 1.0) {
        currentStage++;
        progress = 0.0;
        isTransitioning = false;
      }
    }
  }

  int _initialStage = 0;

  void updateBiome(double score, double speed) {
    int targetStage = _initialStage + (score / biomeScoreInterval).floor();

    if (targetStage > currentStage && !isTransitioning) {
      isTransitioning = true;
      progress = 0.0;
      game.particlePool.emitBiomeTransition();
    }
  }

  int get currentBiomeIndex => currentStage % biomes.length;
  int get nextBiomeIndex => (currentStage + 1) % biomes.length;

  Biome get current => biomes[currentBiomeIndex];
  Biome get next => biomes[nextBiomeIndex];

  /// Effective active biome. Switches at progress >= 0.5 under peak fog opacity.
  Biome get effectiveBiome => (isTransitioning && progress >= 0.5) ? next : current;

  /// Fog opacity curves from 0 at progress=0 to 1 at progress=0.5 back to 0 at progress=1.0.
  double get fogOpacity => isTransitioning ? math.sin(progress * math.pi) : 0.0;

  Color get interpolatedSkyTop =>
      Color.lerp(current.skyTop, next.skyTop, isTransitioning ? progress : 0.0)!;
  Color get interpolatedSkyBottom =>
      Color.lerp(current.skyBottom, next.skyBottom, isTransitioning ? progress : 0.0)!;
  Color get interpolatedGroundTop =>
      Color.lerp(current.groundTop, next.groundTop, isTransitioning ? progress : 0.0)!;
  Color get interpolatedGroundBottom =>
      Color.lerp(current.groundBottom, next.groundBottom, isTransitioning ? progress : 0.0)!;

  void reset({int startingStage = 0}) {
    _initialStage = startingStage;
    currentStage = startingStage;
    progress = 0.0;
    isTransitioning = false;
  }

  bool get isRaining =>
      effectiveBiome.name == 'RAIN' || (isTransitioning && (current.name == 'RAIN' || next.name == 'RAIN'));
}

