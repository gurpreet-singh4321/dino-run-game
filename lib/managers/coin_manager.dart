import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent coin balance and unlocked skins.
/// This is the foundation for a shop system.
class CoinManager {
  static const String _coinKey = 'dino_coins';
  static const String _skinsKey = 'dino_unlocked_skins';
  static const String _activeSkinKey = 'dino_active_skin';
  static const String _highScoreKey = 'dino_high_score';

  int _coins = 0;
  int _runCoins = 0;
  int _highScore = 0;
  Set<String> _unlockedSkins = {'default_dino'};
  String _activeSkinId = 'default_dino';

  int get coins => _coins;
  int get runCoins => _runCoins;
  int get highScore => _highScore;
  String get activeSkinId => _activeSkinId;
  Set<String> get unlockedSkins => _unlockedSkins;

  void resetRunCoins() {
    _runCoins = 0;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt(_coinKey) ?? 0;
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
      _activeSkinId = prefs.getString(_activeSkinKey) ?? 'default_dino';
      final skinsList = prefs.getStringList(_skinsKey);
      if (skinsList != null) {
        _unlockedSkins = skinsList.toSet();
      }
      _unlockedSkins.add('default_dino'); // Always unlocked
    } catch (_) {
      // SharedPreferences might not be available in all environments
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinKey, _coins);
      await prefs.setInt(_highScoreKey, _highScore);
      await prefs.setString(_activeSkinKey, _activeSkinId);
      await prefs.setStringList(_skinsKey, _unlockedSkins.toList());
    } catch (_) {}
  }

  void addCoins(int amount) {
    _runCoins += amount;
    _coins += amount;
    _save();
  }

  bool tryPurchaseSkin(String skinId, int price) {
    if (_unlockedSkins.contains(skinId)) return true; // Already owned
    if (_coins < price) return false;
    _coins -= price;
    _unlockedSkins.add(skinId);
    _save();
    return true;
  }

  void setActiveSkin(String skinId) {
    if (_unlockedSkins.contains(skinId)) {
      _activeSkinId = skinId;
      _save();
    }
  }

  bool isSkinUnlocked(String skinId) => _unlockedSkins.contains(skinId);

  void updateHighScore(int score) {
    if (score > _highScore) {
      _highScore = score;
      _save();
    }
  }
}
