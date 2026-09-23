import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';
import 'package:dino_run_epochs/skins/skin_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Unreleased characters cannot be purchased or selected', () async {
    final manager = CoinManager();
    await manager.load();
    manager.addCoins(10000);
    for (final skin in SkinRegistry.all.where((s) => !SkinRegistry.isAvailable(s.id))) {
      final balance = manager.coins;
      expect(manager.tryPurchaseSkin(skin.id, 0), isFalse);
      manager.setActiveSkin(skin.id);
      expect(manager.activeSkinId, 'new_dino');
      expect(manager.coins, balance);
    }
    expect(SkinRegistry.playable.map((s) => s.id), ['new_dino']);
  });

  test('Existing save migrates to the only Dino without losing coins', () async {
    SharedPreferences.setMockInitialValues({
      'dino_active_skin': 'rive_dino', 'dino_unlocked_skins': ['rive_dino'],
      'dino_coins': 420,
    });
    final manager = CoinManager();
    await manager.load();
    expect(manager.activeSkinId, 'new_dino');
    expect(manager.coins, 420);
    expect(manager.isSkinUnlocked('new_dino'), isTrue);
    expect(SkinRegistry.getById('new_dino').displayName, 'Dino');
  });

  test('One purchase serves both characters and survives reload', () async {
    final manager = CoinManager();
    await manager.load();
    final balance = manager.coins;
    expect(await manager.purchaseCosmetic('explorer_hat'), isTrue);
    expect(await manager.purchaseCosmetic('explorer_hat'), isTrue);
    expect(manager.coins, balance - 250);
    await manager.equipCosmetic('explorer_hat');
    manager.setActiveSkin('new_dino');
    await manager.forceSave();
    SkinRegistry.setCosmetics(manager.equippedCosmetics.values);
    for (final skin in SkinRegistry.all) {
      expect(skin.cosmetics.single.id, 'explorer_hat');
    }
    final restored = CoinManager();
    await restored.load();
    expect(restored.activeSkinId, 'new_dino');
    expect(restored.equippedCosmetics[CosmeticSlot.head], 'explorer_hat');
    expect(restored.coins, balance - 250);
  });

  test('Slots replace independently and invalid or unowned items cannot equip', () async {
    final manager = CoinManager();
    await manager.load();
    expect(await manager.equipCosmetic('explorer_pack'), isFalse);
    expect(await manager.purchaseCosmetic('invalid'), isFalse);
    await manager.equipCosmetic('red_scarf');
    await manager.purchaseCosmetic('explorer_hat');
    await manager.equipCosmetic('explorer_hat');
    await manager.purchaseCosmetic('winter_hat');
    await manager.equipCosmetic('winter_hat');
    expect(manager.equippedCosmetics.length, 2);
    expect(manager.equippedCosmetics[CosmeticSlot.head], 'winter_hat');
    await manager.removeCosmetic(CosmeticSlot.head);
    expect(manager.equippedCosmetics.values, ['red_scarf']);
  });

  test('Insufficient balance never buys an item', () async {
    SharedPreferences.setMockInitialValues({'dino_coins': 10});
    final manager = CoinManager();
    await manager.load();
    expect(await manager.purchaseCosmetic('explorer_hat'), isFalse);
    expect(manager.coins, 10);
    expect(manager.ownsCosmetic('explorer_hat'), isFalse);
  });
}
