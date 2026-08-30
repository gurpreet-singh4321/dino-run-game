import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent coin balance, upgrades, unlocked skins, daily rewards, and missions.
class CoinManager {
  static const String _coinKey = 'dino_coins';
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
  Set<String> _unlockedSkins = {'rive_dino', 'default'};
  String _activeSkinId = 'rive_dino';

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
      _coins = prefs.getInt(_coinKey) ?? 2350; // generous starting coins for testing
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
      _activeSkinId = prefs.getString(_activeSkinKey) ?? 'rive_dino';
      
      final skinsList = prefs.getStringList(_skinsKey);
      if (skinsList != null) {
        _unlockedSkins = skinsList.toSet();
      }
      _unlockedSkins.add('rive_dino');
      _unlockedSkins.add('default');

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
    } catch (_) {
      // SharedPreferences fallback
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinKey, _coins);
      await prefs.setInt(_highScoreKey, _highScore);
      await prefs.setString(_activeSkinKey, _activeSkinId);
      await prefs.setStringList(_skinsKey, _unlockedSkins.toList());

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
    } catch (_) {}
  }

  void addCoins(int amount) {
    _runCoins += amount;
    _coins += amount;
    _save();
  }

  bool spendCoins(int amount) {
    if (_coins < amount) return false;
    _coins -= amount;
    _save();
    return true;
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

  void claimDailyReward({int rewardCoins = 150}) {
    if (!canClaimDailyReward) return;
    _lastDailyClaimDate = _getTodayString();
    _dailyStreak = (_dailyStreak % 7) + 1;
    addCoins(rewardCoins);
    _save();
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
