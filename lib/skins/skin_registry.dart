import 'skin.dart';
import 'new_dino_skin.dart';
import 'cosmetics.dart';

/// Registry of all available character skins.
class SkinRegistry {
  SkinRegistry._();

  static final List<CharacterSkin> _all = [NewDinoSkin()];

  static bool isAvailable(String id) => id == 'new_dino';
  static List<CharacterSkin> get playable => all.where((s) => isAvailable(s.id)).toList();

  /// All registered skins.
  static List<CharacterSkin> get all => List.unmodifiable(_all);

  static void setCosmetics(Iterable<String> ids) {
    final items = List<CosmeticItem>.unmodifiable(
      ids.map(CosmeticCatalog.find).whereType<CosmeticItem>());
    for (final skin in _all) {
      skin.cosmetics = items;
    }
  }

  /// Get a skin by its unique ID.
  static CharacterSkin getById(String id) {
    return _all.firstWhere((s) => s.id == id && isAvailable(id), orElse: () => _all.first);
  }

  /// The default skin.
  static CharacterSkin get defaultSkin => _all.first;

  /// Register a new skin at runtime (e.g., from a DLC or plugin).
  static void register(CharacterSkin skin) {
    if (!_all.any((s) => s.id == skin.id)) {
      _all.add(skin);
      skin.cosmetics = _all.first.cosmetics;
    }
  }
}
