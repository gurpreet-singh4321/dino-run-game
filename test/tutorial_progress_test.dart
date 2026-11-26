import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('A new player sees onboarding once, including across reloads', () async {
    SharedPreferences.setMockInitialValues({'dino_coins': 321});
    final wallet = CoinManager();
    await wallet.load();
    expect(wallet.hasSeenTutorial, isFalse);
    final saving = wallet.markTutorialSeen();
    expect(wallet.hasSeenTutorial, isTrue);
    await saving;
    final reloaded = CoinManager();
    await reloaded.load();
    expect(reloaded.hasSeenTutorial, isTrue);
    expect(reloaded.coins, 321);
    await reloaded.markTutorialSeen();
    expect(reloaded.coins, 321);
  });
  test('Existing runners skip onboarding without losing progress', () async {
    SharedPreferences.setMockInitialValues({
      'dino_high_score': 8000,
      'dino_coins': 900,
    });
    final wallet = CoinManager();
    await wallet.load();
    expect(wallet.hasSeenTutorial, isTrue);
    expect(wallet.highScore, 8000);
    expect(wallet.coins, 900);
  });
}
