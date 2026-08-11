import 'skin.dart';
import 'default_dino_skin.dart';
import 'rive_dino_skin.dart';

/// Registry of all available character skins.
///
/// To add a new skin:
/// 1. Create a class extending `CharacterSkin` (see `DefaultDinoSkin`)
/// 2. Add an instance to the `_all` list below
/// 3. That's it — it will appear in the shop automatically
class SkinRegistry {
  SkinRegistry._();

  static final List<CharacterSkin> _all = [
    RiveDinoSkin(),
    DefaultDinoSkin(),
    // Add new skins here:
    // NinjaDinoSkin(),
    // RobotDinoSkin(),
    // FlamingoSkin(),
  ];

  /// All registered skins.
  static List<CharacterSkin> get all => List.unmodifiable(_all);

  /// Get a skin by its unique ID.
  static CharacterSkin getById(String id) {
    return _all.firstWhere((s) => s.id == id, orElse: () => _all.first);
  }

  /// The default skin.
  static CharacterSkin get defaultSkin => _all.first;

  /// Register a new skin at runtime (e.g., from a DLC or plugin).
  static void register(CharacterSkin skin) {
    if (!_all.any((s) => s.id == skin.id)) {
      _all.add(skin);
    }
  }
}
