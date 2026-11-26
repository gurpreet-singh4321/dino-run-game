import '../skins/cart_skins.dart';
import '../skins/skin_registry.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../skins/cosmetics.dart';

/// Manages persistent coin balance, upgrades, unlocked skins, daily rewards, and missions.
class CoinManager {
  static const String _coinKey = 'dino_coins';
  static const String _tutorialKey = 'dino_tutorial_seen';
  bool _hasSeenTutorial = false;
  bool get hasSeenTutorial => _hasSeenTutorial;

  Future<void> markTutorialSeen() async {
    if (_hasSeenTutorial) return;
    _hasSeenTutorial = true;
    _dirty = true;
    await forceSave();
  }

  static const String _skinsKey = 'dino_unlocked_skins';
  static const String _activeSkinKey = 'dino_active_skin';
  static const String _highScoreKey = 'dino_high_score';

  // Upgrades
  static const String _magnetLevelKey = 'dino_upgrade_magnet';
  static const String _shieldLevelKey = 'dino_upgrade_shield';
  static const String _cosmicLevelKey = 'dino_upgrade_cosmic';
  static const String _multiplierLevelKey = 'dino_upgrade_multiplier';

  // Daily Rewards
  static const String _lastClaimDateKey = 'dino_last_daily_claim';
  static const String _streakKey = 'dino_daily_streak';

  // Missions & Stats
  static const String _claimedMissionsKey = 'dino_claimed_missions';
  static const String _totalJumpsKey = 'dino_stat_jumps';
  static const String _shieldHitsKey = 'dino_stat_shield_hits';
  static const String _spaceTripsKey = 'dino_stat_space_trips';

  int _coins = 0;
  int _runCoins = 0;
  int _highScore = 0;
  Set<String> _unlockedSkins = {'new_dino'};
  final Set<String> _ownedCosmetics = {'red_scarf'};
  final Map<CosmeticSlot, String> _equippedCosmetics = {};
  Map<CosmeticSlot, String> get equippedCosmetics =>
      Map.unmodifiable(_equippedCosmetics);
  bool ownsCosmetic(String id) => _ownedCosmetics.contains(id);

  Future<bool> purchaseCosmetic(String id) async {
    final item = CosmeticCatalog.find(id);
    if (item == null) return false;
    if (_ownedCosmetics.contains(id)) return true;
    if (_coins < item.price) return false;
    _coins -= item.price;
    _ownedCosmetics.add(id);
    await _save();
    await forceSave();
    return true;
  }

  Future<bool> equipCosmetic(String id) async {
    final item = CosmeticCatalog.find(id);
    if (item == null || !_ownedCosmetics.contains(id)) return false;
    _equippedCosmetics[item.slot] = id;
    await _save();
    await forceSave();
    return true;
  }

  Future<void> removeCosmetic(CosmeticSlot slot) async {
    _equippedCosmetics.remove(slot);
    await _save();
    await forceSave();
  }

  final Set<String> _ownedCartSkins = {'fossil_rover'};
  String _equippedCartSkin = 'fossil_rover';
  String get equippedCartSkin => _equippedCartSkin;
  bool ownsCartSkin(String id) => _ownedCartSkins.contains(id);
  Future<bool> purchaseCartSkin(String id) async {
    final item = CartSkinCatalog.find(id);
    if (item == null) return false;
    if (ownsCartSkin(id)) return true;
    if (_coins < item.price) return false;
    _coins -= item.price;
    _ownedCartSkins.add(id);
    await _save();
    await forceSave();
    return true;
  }

  Future<bool> equipCartSkin(String id) async {
    if (!ownsCartSkin(id) || CartSkinCatalog.find(id) == null) return false;
    _equippedCartSkin = id;
    await _save();
    await forceSave();
    return true;
  }

  String _activeSkinId = 'new_dino';

  // Upgrades (Level 0 = base, max level = 5)
  int _magnetLevel = 0;
  int _shieldLevel = 0;
  int _cosmicLevel = 0;
  int _multiplierLevel = 0;

  // Daily reward
  String? _lastDailyClaimDate;
  int _dailyStreak = 1;

  // Missions & Stats
  Set<int> _claimedMissions = {};
  int _totalJumps = 0;
  int _shieldHits = 0;
  int _spaceTrips = 0;
  int _collectedCoins = 0;
  int get collectedCoins => _collectedCoins;

  int get coins => _coins;
  int get runCoins => _runCoins;
  int get highScore => _highScore;
  String get activeSkinId => _activeSkinId;
  Set<String> get unlockedSkins => _unlockedSkins;

  int get magnetLevel => _magnetLevel;
  int get shieldLevel => _shieldLevel;
  int get cosmicLevel => _cosmicLevel;
  int get multiplierLevel => _multiplierLevel;

  int get dailyStreak => _dailyStreak;
  Set<int> get claimedMissions => _claimedMissions;
  int get totalJumps => _totalJumps;
  int get shieldHits => _shieldHits;
  int get spaceTrips => _spaceTrips;

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool get canClaimDailyReward {
    final today = _getTodayString();
    return _lastDailyClaimDate != today;
  }

  void resetRunCoins() {
    _runCoins = 0;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt(_coinKey) ?? 0;
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
      // Existing runners should not be sent back into onboarding.
      _hasSeenTutorial = prefs.getBool(_tutorialKey) ?? (_highScore > 0);
      _activeSkinId = prefs.getString(_activeSkinKey) ?? 'new_dino';
      if (!SkinRegistry.isAvailable(_activeSkinId)) _activeSkinId = 'new_dino';

      final skinsList = prefs.getStringList(_skinsKey);
      if (skinsList != null) {
        _unlockedSkins = skinsList.toSet();
      }
      _unlockedSkins.add('new_dino');
      _ownedCosmetics.addAll(
        (prefs.getStringList('dino_owned_cosmetics') ?? []).where(
          (id) => CosmeticCatalog.find(id) != null,
        ),
      );
      _equippedCosmetics.clear();
      for (final id
          in prefs.getStringList('dino_equipped_cosmetics') ?? <String>[]) {
        final item = CosmeticCatalog.find(id);
        if (item != null && _ownedCosmetics.contains(id)) {
          _equippedCosmetics[item.slot] = id;
        }
      }

      _ownedCartSkins.addAll(
        (prefs.getStringList('dino_owned_cart_skins') ?? []).where(
          (id) => CartSkinCatalog.find(id) != null,
        ),
      );
      final cartId = prefs.getString('dino_equipped_cart_skin');
      _equippedCartSkin = cartId != null && ownsCartSkin(cartId)
          ? cartId
          : 'fossil_rover';

      _magnetLevel = prefs.getInt(_magnetLevelKey) ?? 0;
      _shieldLevel = prefs.getInt(_shieldLevelKey) ?? 0;
      _cosmicLevel = prefs.getInt(_cosmicLevelKey) ?? 0;
      _multiplierLevel = prefs.getInt(_multiplierLevelKey) ?? 0;

      _lastDailyClaimDate = prefs.getString(_lastClaimDateKey);
      _dailyStreak = prefs.getInt(_streakKey) ?? 1;

      final missionsList = prefs.getStringList(_claimedMissionsKey);
      if (missionsList != null) {
        _claimedMissions = missionsList.map(int.parse).toSet();
      }

      _totalJumps = prefs.getInt(_totalJumpsKey) ?? 0;
      _shieldHits = prefs.getInt(_shieldHitsKey) ?? 0;
      _spaceTrips = prefs.getInt(_spaceTripsKey) ?? 0;
      // Old wallets include grants and spending: never infer collection from them.
      _collectedCoins = prefs.getInt('dino_stat_collected_coins') ?? 0;
    } catch (_) {
      // SharedPreferences fallback
    }
  }

  // Debounced save — batch writes, max once per 2 seconds
  bool _dirty = false;
  Timer? _saveTimer;
  Future<void> _pendingSave = Future.value();

  Future<void> _save() async {
    _dirty = true;
    if (_saveTimer == null || !_saveTimer!.isActive) {
      _saveTimer = Timer(const Duration(seconds: 2), () => _flushSave());
    }
  }

  /// Force an immediate save (call on game-over, app-pause, purchase).
  Future<void> forceSave() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await _flushSave();
  }

  Future<void> _flushSave() {
    _saveTimer = null;
    return _pendingSave = _pendingSave.then((_) => _writeDirtyProgress());
  }

  Future<void> _writeDirtyProgress() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinKey, _coins);
      await prefs.setInt(_highScoreKey, _highScore);
      await prefs.setBool(_tutorialKey, _hasSeenTutorial);
      await prefs.setString(_activeSkinKey, _activeSkinId);
      await prefs.setStringList(_skinsKey, _unlockedSkins.toList());
      await prefs.setStringList(
        'dino_owned_cosmetics',
        _ownedCosmetics.toList(),
      );
      await prefs.setStringList(
        'dino_equipped_cosmetics',
        _equippedCosmetics.values.toList(),
      );

      await prefs.setInt(_magnetLevelKey, _magnetLevel);
      await prefs.setInt(_shieldLevelKey, _shieldLevel);
      await prefs.setInt(_cosmicLevelKey, _cosmicLevel);
      await prefs.setInt(_multiplierLevelKey, _multiplierLevel);

      if (_lastDailyClaimDate != null) {
        await prefs.setString(_lastClaimDateKey, _lastDailyClaimDate!);
      }
      await prefs.setInt(_streakKey, _dailyStreak);

      await prefs.setStringList(
        _claimedMissionsKey,
        _claimedMissions.map((id) => id.toString()).toList(),
      );

      await prefs.setInt(_totalJumpsKey, _totalJumps);
      await prefs.setInt(_shieldHitsKey, _shieldHits);
      await prefs.setInt(_spaceTripsKey, _spaceTrips);
      await prefs.setInt('dino_stat_collected_coins', _collectedCoins);
      await prefs.setStringList(
        'dino_owned_cart_skins',
        _ownedCartSkins.toList(),
      );
      await prefs.setString('dino_equipped_cart_skin', _equippedCartSkin);
      await prefs.setInt('dino_save_version', 3);
      if (_dirty) await _writeDirtyProgress();
    } catch (_) {
      _dirty = true;
    }
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _save();
  }

  /// Only gameplay pickups count towards collection goals and run rewards.
  void collectCoins(int amount) {
    if (amount <= 0) return;
    _runCoins += amount;
    _collectedCoins += amount;
    addCoins(amount);
  }

  bool spendCoins(int amount) {
    if (_coins < amount) return false;
    _coins -= amount;
    _save();
    return true;
  }

  bool tryPurchaseSkin(String skinId, int price) {
    if (!SkinRegistry.isAvailable(skinId)) return false;
    if (_unlockedSkins.contains(skinId)) return true; // Already owned
    if (_coins < price) return false;
    _coins -= price;
    _unlockedSkins.add(skinId);
    _save();
    return true;
  }

  void setActiveSkin(String skinId) {
    if (SkinRegistry.isAvailable(skinId) && _unlockedSkins.contains(skinId)) {
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

  // --- Upgrades System ---

  int getUpgradeLevel(String upgradeId) {
    switch (upgradeId) {
      case 'magnet':
        return _magnetLevel;
      case 'shield':
        return _shieldLevel;
      case 'cosmic':
        return _cosmicLevel;
      case 'multiplier':
        return _multiplierLevel;
      default:
        return 0;
    }
  }

  bool upgradePowerup(String upgradeId, int cost) {
    if (_coins < cost) return false;
    final currentLevel = getUpgradeLevel(upgradeId);
    if (currentLevel >= 5) return false;

    _coins -= cost;
    switch (upgradeId) {
      case 'magnet':
        _magnetLevel++;
        break;
      case 'shield':
        _shieldLevel++;
        break;
      case 'cosmic':
        _cosmicLevel++;
        break;
      case 'multiplier':
        _multiplierLevel++;
        break;
    }
    _save();
    return true;
  }

  // --- Daily Rewards ---

  int claimDailyReward({int? rewardCoins, int baseRewardCoins = 150}) {
    if (!canClaimDailyReward) return 0;
    final base = rewardCoins ?? baseRewardCoins;
    final today = DateTime.now();
    final todayStr = _getTodayString();

    if (_lastDailyClaimDate != null) {
      try {
        final last = DateTime.parse(_lastDailyClaimDate!);
        final todayUtc = DateTime.utc(today.year, today.month, today.day);
        final lastUtc = DateTime.utc(last.year, last.month, last.day);
        final diff = todayUtc.difference(lastUtc).inDays;

        if (diff == 1) {
          _dailyStreak = (_dailyStreak % 7) + 1;
        } else if (diff > 1) {
          _dailyStreak = 1;
        }
      } catch (_) {
        _dailyStreak = 1;
      }
    } else {
      _dailyStreak = 1;
    }

    _lastDailyClaimDate = todayStr;
    final totalReward = base + (_dailyStreak * 50);
    addCoins(totalReward);
    forceSave();
    return totalReward;
  }

  // --- Missions ---

  bool isMissionClaimed(int missionId) => _claimedMissions.contains(missionId);

  void claimMission(int missionId, int rewardCoins) {
    if (_claimedMissions.contains(missionId)) return;
    _claimedMissions.add(missionId);
    addCoins(rewardCoins);
    _save();
  }

  // --- Stats Increment ---

  void recordJump() {
    _totalJumps++;
    _save();
  }

  void recordShieldHit() {
    _shieldHits++;
    _save();
  }

  void recordSpaceTrip() {
    _spaceTrips++;
    _save();
  }
}
