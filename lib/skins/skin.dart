import 'dart:ui';
import 'dart:math' as math;
import 'cosmetics.dart';

enum CharacterPose { running, jumping, falling, space }

/// Base class for character skins. Extend this to add new costumes.
/// Each skin defines how the character is drawn on the canvas.
///
/// To add a new skin:
/// 1. Create a new class extending `CharacterSkin`
/// 2. Override `renderRunning`, `renderJumping`, `renderSpace`
/// 3. Register it in `SkinRegistry`
abstract class CharacterSkin {
  bool get hasArticulatedMotion => false;
  void resetMotion() {}
  void onJump() {}
  void advanceMotion(double dt, {required double speed,
      required double velocityY, required bool grounded,
      bool idle = false, bool space = false, double characterWidth = 80}) => update(dt);
  List<CosmeticItem> cosmetics = const [];
  CosmeticFit get cosmeticFit => const CosmeticFit();
  CosmeticFit cosmeticFitFor(Size size) => cosmeticFit;

  /// Shared render entry point for menu, shop and gameplay.
  /// Accessories use the same pose transform as the base character.
  void renderCharacter(Canvas canvas, Size size, int frame,
      {CharacterPose pose = CharacterPose.running}) {
    canvas.save();
    applyPose(canvas, size, frame, pose);
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.back)) {
      drawCosmetic(canvas, size, cosmeticFitFor(size), item);
    }
    switch (pose) {
      case CharacterPose.running: renderRunning(canvas, size, frame);
      case CharacterPose.jumping: renderJumping(canvas, size, false);
      case CharacterPose.falling: renderJumping(canvas, size, true);
      case CharacterPose.space: renderSpace(canvas, size, frame);
    }
    for (final item in cosmetics.where((i) => i.slot != CosmeticSlot.back)) {
      drawCosmetic(canvas, size, cosmeticFitFor(size), item);
    }
    canvas.restore();
  }

  void applyPose(Canvas canvas, Size size, int frame, CharacterPose pose) {}

  /// Unique identifier for persistence (shop purchases, etc.)
  String get id;

  /// Display name shown in the shop / selection UI.
  String get displayName;

  /// Alias for displayName
  String get name => displayName;

  /// Flavor description
  String get description => '';

  /// Rarity tag (Common, Rare, Epic, Legendary)
  String get rarity => 'Common';

  /// Price in coins. 0 = free / default.
  int get price;

  /// Whether the skin is unlocked by default.
  bool get unlockedByDefault => price == 0;

  /// Primary body color (used for UI previews).
  Color get primaryColor;

  double blinkTimer = 0;
  bool isBlinking = false;
  static final math.Random _rng = math.Random();

  /// Update animation logic (used by animated skins like Rive).
  void update(double dt) {
    blinkTimer -= dt;
    if (blinkTimer <= 0) {
      if (isBlinking) {
        isBlinking = false;
        blinkTimer = 2.5 + _rng.nextDouble() * 2.5;
      } else {
        isBlinking = true;
        blinkTimer = 0.09;
      }
    }
  }

  /// Draw the character in running state.
  /// [canvas] is translated so (0,0) is the top-left of the character bounds.
  /// [size] is the bounding box (width, height).
  /// [animFrame] cycles 0-3 at ~100ms per frame.
  void renderRunning(Canvas canvas, Size size, int animFrame);

  /// Draw the character in jumping/falling state.
  void renderJumping(Canvas canvas, Size size, bool isFalling);

  /// Draw the character in space float mode.
  /// [animFrame] cycles 0-3.
  void renderSpace(Canvas canvas, Size size, int animFrame);

  /// Optional: draw a powerup aura overlay.
  void renderAura(Canvas canvas, Size size, Color auraColor, double timer) {
    final paint = Paint()
      ..color = auraColor.withValues(alpha: 0.3 + 0.1 * (timer % 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width + 8,
        height: size.height + 8,
      ),
      paint,
    );
  }
}
