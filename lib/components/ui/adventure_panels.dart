import 'package:flutter/material.dart';
import '../../game/dino_game.dart';
import '../../skins/cosmetics.dart';
import '../../skins/skin_registry.dart';
import '../../managers/audio_manager.dart';

const _ink = Color(0xFF173B48);
const _cream = Color(0xFFFFF1CE);
const _gold = Color(0xFFFFCA62);

class AdventurePanel extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final int? coins;
  final VoidCallback? onClose;
  const AdventurePanel({super.key, required this.title, required this.subtitle,
    required this.child, this.coins, this.onClose});
  @override
  Widget build(BuildContext context) => Material(color: const Color(0xAA071B27),
    child: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Center(
      child: Container(constraints: const BoxConstraints(maxWidth: 980),
        decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gold, width: 2), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 30, offset: Offset(0, 8))]),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(18, 10, 8, 10), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF58716C))),
            ])),
            if (coins != null) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(16)),
              child: Text('● $coins', style: const TextStyle(color: _ink, fontWeight: FontWeight.w900))),
            IconButton(tooltip: 'Close panel', onPressed: onClose ?? () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _ink)),
          ])),
          const Divider(height: 1, color: Color(0xFFD8CBA8)),
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: child)),
        ]),
      ),
    ))));
}

void _celebrate(BuildContext context, String title) {
  AudioManager.playUpgrade();
  showDialog<void>(context: context, builder: (context) => AlertDialog(
    icon: const Icon(Icons.auto_awesome_rounded, color: _gold, size: 54),
    title: Text(title, textAlign: TextAlign.center),
    content: const Text('A little more adventure. A little more you!', textAlign: TextAlign.center),
    actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Awesome!'))],
  ));
}

class AdventureUpgrades extends StatefulWidget {
  final DinoGame game;
  const AdventureUpgrades({super.key, required this.game});
  @override
  State<AdventureUpgrades> createState() => _AdventureUpgradesState();
}
class _AdventureUpgradesState extends State<AdventureUpgrades> {
  @override
  Widget build(BuildContext context) {
    final wallet = widget.game.coinManager;
    const ids = ['magnet', 'shield', 'cosmic', 'multiplier'];
    const names = ['Coin magnet', 'Bubble shield', 'Star rocket', 'Lucky stars'];
    const descriptions = ['Bring more coins to Dino.', 'Keep your little explorer safe.', 'Go further among the stars.', 'Find more double-coin surprises.'];
    const icons = [Icons.attractions_rounded, Icons.shield_rounded, Icons.rocket_launch_rounded, Icons.stars_rounded];
    const colors = [Color(0xFFD97566), Color(0xFF419EAB), Color(0xFF7C83BD), Color(0xFFDEA63A)];
    return AdventurePanel(title: 'Adventure boosts', subtitle: 'Little upgrades. Bigger adventures.', coins: wallet.coins,
      child: LayoutBuilder(builder: (context, size) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size.maxWidth >= 760 ? 4 : 2,
          mainAxisExtent: 246, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: 4, itemBuilder: (context, index) {
          final level = wallet.getUpgradeLevel(ids[index]);
          final maxed = level >= 5;
          final cost = maxed ? 0 : [500, 1000, 2500, 5000, 10000][level];
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors[index].withValues(alpha: .4))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(height: 52, decoration: BoxDecoration(color: colors[index].withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
                child: Icon(icons[index], color: colors[index], size: 36)),
              const SizedBox(height: 8),
              Text(names[index], style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 3),
              Text(descriptions[index], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF58716C), fontSize: 11)),
              const Spacer(),
              Row(children: List.generate(5, (i) => Expanded(child: Container(height: 6, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: i < level ? colors[index] : const Color(0xFFE7E9DF), borderRadius: BorderRadius.circular(4)))))),
              const SizedBox(height: 8),
              FilledButton(onPressed: maxed || wallet.coins < cost ? null : () {
                if (wallet.upgradePowerup(ids[index], cost)) {
                  setState(() {});
                  _celebrate(context, '${names[index]} · Level ${level + 1}!');
                }
              }, child: Text(maxed ? 'Fully upgraded' : 'Upgrade · $cost')),
            ]));
        })),
    );
  }
}

class AdventureWardrobe extends StatefulWidget {
  final DinoGame game;
  const AdventureWardrobe({super.key, required this.game});
  @override
  State<AdventureWardrobe> createState() => _AdventureWardrobeState();
}
class _AdventureWardrobeState extends State<AdventureWardrobe> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final wallet = widget.game.coinManager;
    return AdventurePanel(title: 'Dino’s dressing room', subtitle: 'Pick a little personality for your next run.', coins: wallet.coins,
      child: Row(children: [
        Expanded(flex: 3, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          gradient: const RadialGradient(colors: [Color(0xFFFFD881), Color(0xFFFFEBC0)])),
          child: Column(children: [
            Expanded(child: LayoutBuilder(builder: (context, size) {
              final height = (size.maxWidth * 1.2).clamp(0.0, size.maxHeight);
              return Center(child: SizedBox(width: height / 1.2, height: height,
                child: CustomPaint(painter: _DressingDino())));
            })),
            const Padding(padding: EdgeInsets.all(12), child: Text('DINO', style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 18))),
          ]))),
        const SizedBox(width: 12),
        Expanded(flex: 5, child: LayoutBuilder(builder: (context, size) => GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size.maxWidth < 290 ? 1 : 2,
            mainAxisExtent: 184, mainAxisSpacing: 10, crossAxisSpacing: 10), itemCount: CosmeticCatalog.items.length,
          itemBuilder: (context, index) {
            final item = CosmeticCatalog.items[index];
            final owned = wallet.ownsCosmetic(item.id);
            final equipped = wallet.equippedCosmetics[item.slot] == item.id;
            return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: equipped ? const Color(0xFFE1F1D9) : Colors.white,
              borderRadius: BorderRadius.circular(18), border: Border.all(color: equipped ? const Color(0xFF62A980) : const Color(0xFFE0D8BE), width: equipped ? 2 : 1)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(height: 68, child: CustomPaint(painter: _AccessoryArt(item))),
                Text(item.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w900)),
                const Spacer(),
                FilledButton(onPressed: busy || (!owned && wallet.coins < item.price) ? null : () async {
                  setState(() => busy = true);
                  if (equipped) {
                    await wallet.removeCosmetic(item.slot);
                  } else {
                    final purchased = owned || await wallet.purchaseCosmetic(item.id);
                    if (purchased) await wallet.equipCosmetic(item.id);
                  }
                  SkinRegistry.setCosmetics(wallet.equippedCosmetics.values);
                  if (!mounted) return;
                  setState(() => busy = false);
                  if (!owned && wallet.ownsCosmetic(item.id)) _celebrate(this.context, '${item.name} unlocked!');
                }, child: Text(equipped ? 'Take off' : owned ? 'Wear it' : 'Unlock · ${item.price}')),
              ]));
          }))),
      ]));
  }
}
class _DressingDino extends CustomPainter {
  @override
  void paint(Canvas c, Size size) => SkinRegistry.defaultSkin.renderCharacter(c, size, 0);
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
class _AccessoryArt extends CustomPainter {
  final CosmeticItem item;
  _AccessoryArt(this.item);
  @override
  void paint(Canvas c, Size size) {
    final scale = size.height / 75;
    c.save();
    c.translate(size.width / 2 - 50 * scale, 0);
    c.scale(scale);
    drawCosmetic(c, const Size(100, 75), const CosmeticFit(head: Offset(.5,.6), neck: Offset(.5,.45), back: Offset(.5,.4), scale: 1), item);
    c.restore();
  }
  @override
  bool shouldRepaint(_AccessoryArt old) => old.item.id != item.id;
}
