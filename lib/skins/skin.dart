import 'dart:ui';

/// Base class for character skins. Extend this to add new costumes.
/// Each skin defines how the character is drawn on the canvas.
///
/// To add a new skin:
/// 1. Create a new class extending `CharacterSkin`
/// 2. Override `renderRunning`, `renderJumping`, `renderSpace`
/// 3. Register it in `SkinRegistry`
abstract class CharacterSkin {
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

  /// Update animation logic (used by animated skins like Rive).
  void update(double dt) {}

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
