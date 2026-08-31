import 'package:flutter/material.dart';

/// Central color palette — all game colors in one place.
/// Matches the Dino Run: Epochs asset specification.
class GameColors {
  // Dino body
  static const Color dinoBody = Color(0xFF7EE787);
  static const Color dinoBelly = Color(0xFFA5F0AC);
  static const Color dinoEye = Color(0xFF1A1A1A);
  static const Color dinoEyeWhite = Color(0xFFFFFFFF);

  // Powerup auras
  static const Color shieldAura = Color(0xFF00E5FF);
  static const Color magnetAura = Color(0xFFFF80AB);
  static const Color gravityAura = Color(0xFFA855F7);

  // Collectibles
  static const Color coinGold = Color(0xFFFFD700);
  static const Color coinDark = Color(0xFFFF8F00);
  static const Color shieldOrb = Color(0xFF00E5FF);
  static const Color magnetOrb = Color(0xFFFF80AB);
  static const Color gravityOrb = Color(0xFFA855F7);

  // Obstacles
  static const Color cactus = Color(0xFF2E7D32);
  static const Color cactusDark = Color(0xFF1B5E20);
  static const Color rock = Color(0xFF757575);
  static const Color rockDark = Color(0xFF424242);
  static const Color bird = Color(0xFF8D6E63);
  static const Color birdDark = Color(0xFF5D4037);

  // Meteor
  static const Color meteorBody = Color(0xFF5A3E2B);
  static const Color meteorCrater = Color(0xFF3D2B1F);
  static const Color meteorFire = Color(0xFFFF6432);
  static const Color meteorGlow = Color(0xFFFF6B35);

  // UI
  static const Color uiGreen = Color(0xFF7EE787);
  static const Color uiRed = Color(0xFFFF6B6B);
  static const Color uiText = Color(0xFFFFFFFF);
  static const Color uiTextShadow = Color(0x88000000);
  static const Color uiPanel = Color(0xCC1A1A2E);

  // Ground per biome
  static const List<Color> groundTop = [
    Color(0xFFE5B25D), // desert - warm golden sand
    Color(0xFF4CAF50), // forest
    Color(0xFFE0F7FA), // ice
    Color(0xFF3E2723), // volcano
    Color(0xFF311B92), // cosmos
  ];
  static const List<Color> groundBottom = [
    Color(0xFF7A4515), // desert - deep sandstone earth
    Color(0xFF2E7D32), // forest
    Color(0xFFB3E5FC), // ice
    Color(0xFF1B0000), // volcano
    Color(0xFF1A0033), // cosmos
  ];
}
