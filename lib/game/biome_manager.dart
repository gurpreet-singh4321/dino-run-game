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

  static String toRoman(int number) {
    const romanNumerals = [
      MapEntry(1000, 'M'),
      MapEntry(900, 'CM'),
      MapEntry(500, 'D'),
      MapEntry(400, 'CD'),
      MapEntry(100, 'C'),
      MapEntry(90, 'XC'),
      MapEntry(50, 'L'),
      MapEntry(40, 'XL'),
      MapEntry(10, 'X'),
      MapEntry(9, 'IX'),
      MapEntry(5, 'V'),
      MapEntry(4, 'IV'),
      MapEntry(1, 'I'),
    ];
    if (number <= 0) return 'I';
    var result = '';
    var n = number;
    for (final entry in romanNumerals) {
      while (n >= entry.key) {
        result += entry.value;
        n -= entry.key;
      }
    }
    return result;
  }

  static const List<Biome> biomes = [
    Biome(
      name: 'DESERT',
      displayName: 'THE ANCIENT DESERT',
      skyTop: Color(0xFF184988),
      skyBottom: Color(0xFFEAA63F),
      groundTop: Color(0xFFE5B25D),
      groundBottom: Color(0xFF7A4515),
      accentColor: Color(0xFFFFD54F),
    ),
    Biome(
      name: 'RAIN',
      displayName: 'THE JURASSIC MONSOON',
      skyTop: Color(0xFF1E3342),
      skyBottom: Color(0xFF4B6B7C),
      groundTop: Color(0xFF35483E),
      groundBottom: Color(0xFF1A2621),
      accentColor: Color(0xFF4DEEEA),
    ),
    Biome(
      name: 'FOREST',
      displayName: 'THE PRIMEVAL FOREST',
      skyTop: Color(0xFF4CAF50),
      skyBottom: Color(0xFF81C784),
      groundTop: Color(0xFF4CAF50),
      groundBottom: Color(0xFF2E7D32),
      accentColor: Color(0xFF69F0AE),
    ),
    Biome(
      name: 'ICE',
      displayName: 'THE ICE AGE',
      skyTop: Color(0xFFB3E5FC),
      skyBottom: Color(0xFFE1F5FE),
      groundTop: Color(0xFFE0F7FA),
      groundBottom: Color(0xFFB3E5FC),
      accentColor: Color(0xFF80D8FF),
    ),
    Biome(
      name: 'VOLCANO',
      displayName: 'THE VOLCANO INFERNO',
      skyTop: Color(0xFF3E2723),
      skyBottom: Color(0xFFFF7043),
      groundTop: Color(0xFF3E2723),
      groundBottom: Color(0xFF1B0000),
      accentColor: Color(0xFFFF5722),
    ),
    Biome(
      name: 'COSMOS',
      displayName: 'THE COSMIC ORBIT',
      skyTop: Color(0xFF0D0021),
      skyBottom: Color(0xFF1A0033),
      groundTop: Color(0xFF311B92),
      groundBottom: Color(0xFF1A0033),
      accentColor: Color(0xFFE040FB),
    ),
  ];

  @override
  void update(double dt) {
    dt *= game.globalTimeScale;
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
      final incomingBiome = biomes[targetStage % biomes.length];
      game.milestoneOverlay.triggerBiomeCinematic(incomingBiome, targetStage);
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

