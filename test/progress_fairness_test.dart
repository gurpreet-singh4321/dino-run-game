import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'New wallets start empty; grants and mission claims cannot complete collection goals',
    () async {
      SharedPreferences.setMockInitialValues({});
      final coins = CoinManager();
      await coins.load();
      expect(coins.coins, 0);
      coins.addCoins(500);
      coins.claimMission(3, 60);
      expect(coins.collectedCoins, 0);
      expect(coins.runCoins, 0);
      coins.collectCoins(10);
      coins.spendCoins(100);
      expect(coins.collectedCoins, 10);
      expect(coins.runCoins, 10);
      await coins.forceSave();
      final restored = CoinManager();
      await restored.load();
      expect(restored.coins, 470);
      expect(restored.collectedCoins, 10);
      expect(restored.isMissionClaimed(3), isTrue);
    },
  );

  test(
    'Version 1 wallets preserve money, upgrades, records and wardrobe during migration',
    () async {
      SharedPreferences.setMockInitialValues({
        'dino_coins': 2350,
        'dino_high_score': 9000,
        'dino_upgrade_shield': 3,
        'dino_upgrade_magnet': 2,
        'dino_owned_cosmetics': ['explorer_hat'],
        'dino_equipped_cosmetics': ['explorer_hat'],
        'dino_claimed_missions': ['0'],
      });
      final coins = CoinManager();
      await coins.load();
      expect(coins.coins, 2350);
      expect(coins.collectedCoins, 0);
      expect(coins.isMissionClaimed(0), isTrue);
      expect(coins.highScore, 9000);
      expect(coins.shieldLevel, 3);
      expect(coins.magnetLevel, 2);
      expect(coins.equippedCosmetics.values, ['explorer_hat']);
      coins.collectCoins(1);
      await coins.forceSave();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('dino_save_version'), 3);
      expect(prefs.getInt('dino_coins'), 2351);
    },
  );

  test('Concurrent lifecycle flushes wait for all reward changes', () async {
    SharedPreferences.setMockInitialValues({});
    final coins = CoinManager();
    await coins.load();
    coins.collectCoins(5);
    final first = coins.forceSave();
    coins.collectCoins(7);
    final second = coins.forceSave();
    await Future.wait([first, second]);
    final restored = CoinManager();
    await restored.load();
    expect(restored.coins, 12);
    expect(restored.collectedCoins, 12);
  });
}
