import 'dart:ui';
import 'package:flutter/material.dart';
import '../../game/dino_game.dart';
import '../../skins/cosmetics.dart';
import '../../skins/skin_registry.dart';
import '../../managers/audio_manager.dart';

const _gold = Color(0xFFFFCA62);
const _neonCyan = Color(0xFF4DEEEA);

class AdventurePanel extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final int? coins;
  final VoidCallback? onClose;
  const AdventurePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.coins,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _neonCyan,
            brightness: Brightness.dark,
          ),
        ),
        child: Material(
          color: const Color(0x88000000), // Darker backdrop for contrast
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 980, maxHeight: 620),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0A1118), // Rich deep space blue
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0x664DEEEA), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x224DEEEA), blurRadius: 30, spreadRadius: -5),
                          BoxShadow(color: Colors.black87, blurRadius: 40, offset: Offset(0, 15)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(color: _neonCyan, blurRadius: 12),
                                            Shadow(color: _neonCyan, blurRadius: 24),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFB0C4DE),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (coins != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0x22FFCF62),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xAAFFCF62), width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x33FFCF62), blurRadius: 12),
                                      ],
                                    ),
                                    child: Text(
                                      '● $coins',
                                      style: const TextStyle(
                                        color: Color(0xFFFFCF62),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Close panel',
                                  iconSize: 28,
                                  onPressed: onClose ?? () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0x334DEEEA), thickness: 1.5),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

void _celebrate(BuildContext context, String title) {
  AudioManager.playUpgrade();
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xF00A1118),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x884DEEEA), width: 2),
      ),
      icon: const Icon(Icons.auto_awesome_rounded, color: _gold, size: 64),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: _neonCyan, blurRadius: 12)],
        ),
      ),
      content: const Text(
        'A little more adventure. A little more you!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB0C4DE), fontSize: 16),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _neonCyan,
            foregroundColor: const Color(0xFF0A1118),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
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
    const descriptions = [
      'Bring more coins to Dino.',
      'Keep your little explorer safe.',
      'Go further among the stars.',
      'Find more double-coin surprises.',
    ];
    const icons = [
      Icons.attractions_rounded,
      Icons.shield_rounded,
      Icons.rocket_launch_rounded,
      Icons.stars_rounded,
    ];
    const colors = [
      Color(0xFFFF6B6B), // Vibrant Red
      Color(0xFF4DEEEA), // Neon Cyan
      Color(0xFF9D4EDD), // Deep Purple
      Color(0xFFFFCA62), // Bright Gold
    ];

    return AdventurePanel(
      title: 'Adventure boosts',
      subtitle: 'Little upgrades. Bigger adventures.',
      coins: wallet.coins,
      child: LayoutBuilder(
        builder: (context, size) {
          final isDesktop = size.maxWidth >= 760;
          final gridHeight = isDesktop ? 260.0 : (260.0 * 2 + 16.0);
          final canCenter = size.maxHeight >= gridHeight;

          return Align(
            alignment: canCenter ? Alignment.center : Alignment.topCenter,
            child: GridView.builder(
              shrinkWrap: canCenter,
              physics: canCenter
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                mainAxisExtent: 260,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final level = wallet.getUpgradeLevel(ids[index]);
                final maxed = level >= 5;
                final cost = maxed ? 0 : [500, 1000, 2500, 5000, 10000][level];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors[index].withValues(alpha: 0.15),
                        colors[index].withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors[index].withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors[index].withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors[index].withValues(alpha: 0.3),
                              colors[index].withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors[index].withValues(alpha: 0.4)),
                        ),
                        child: Icon(icons[index], color: colors[index], size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        names[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descriptions[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB0C4DE), fontSize: 12),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Expanded(
                            child: Container(
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: i < level ? colors[index] : const Color(0x22FFFFFF),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: i < level
                                    ? [BoxShadow(color: colors[index].withValues(alpha: 0.5), blurRadius: 4)]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: maxed ? const Color(0xFF2A3A4D) : colors[index],
                          foregroundColor: maxed ? const Color(0xFF8DA3B5) : const Color(0xFF0A1118),
                          disabledBackgroundColor: const Color(0x22FFFFFF),
                          disabledForegroundColor: const Color(0x66FFFFFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: maxed ? 0 : 8,
                          shadowColor: colors[index].withValues(alpha: 0.5),
                        ),
                        onPressed: maxed || wallet.coins < cost
                            ? null
                            : () {
                                if (wallet.upgradePowerup(ids[index], cost)) {
                                  setState(() {});
                                  _celebrate(context, '${names[index]} · Level ${level + 1}!');
                                }
                              },
                        child: Text(
                          maxed ? 'Fully upgraded' : 'Upgrade · $cost',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
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
    return AdventurePanel(
      title: 'Dino’s dressing room',
      subtitle: 'Pick a little personality for your next run.',
      coins: wallet.coins,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Glowing golden spotlight for Dino
                gradient: const RadialGradient(
                  center: Alignment(0, 0.1),
                  radius: 0.7,
                  colors: [
                    Color(0x99FFD54F), // Bright center glow
                    Color(0x33FF9800), // Fade to orange
                    Color(0x110A1118), // Fade into space background
                  ],
                ),
                border: Border.all(color: const Color(0x55FFCA62), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x1AFFCA62), blurRadius: 30, spreadRadius: -5),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, size) {
                        final height = (size.maxWidth * 1.2).clamp(0.0, size.maxHeight);
                        return Center(
                          child: SizedBox(
                            width: height / 1.2,
                            height: height,
                            child: CustomPaint(painter: _DressingDino()),
                          ),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'DINO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 4,
                        shadows: [Shadow(color: _gold, blurRadius: 12)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, size) => GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size.maxWidth < 290 ? 1 : 2,
                  mainAxisExtent: 184,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: CosmeticCatalog.items.length,
                itemBuilder: (context, index) {
                  final item = CosmeticCatalog.items[index];
                  final owned = wallet.ownsCosmetic(item.id);
                  final equipped = wallet.equippedCosmetics[item.slot] == item.id;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: equipped
                            ? [const Color(0x444DEEEA), const Color(0x114DEEEA)]
                            : [const Color(0x1AFFFFFF), const Color(0x05FFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: equipped ? _neonCyan : const Color(0x33FFFFFF),
                        width: equipped ? 2 : 1.5,
                      ),
                      boxShadow: equipped
                          ? const [BoxShadow(color: Color(0x334DEEEA), blurRadius: 20, spreadRadius: -5)]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 60, child: CustomPaint(painter: _AccessoryArt(item))),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: equipped ? _neonCyan : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: equipped ? _neonCyan : const Color(0xFF2A3A4D),
                            foregroundColor: equipped ? const Color(0xFF0A1118) : Colors.white,
                            disabledBackgroundColor: const Color(0x22FFFFFF),
                            disabledForegroundColor: const Color(0x66FFFFFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: equipped ? 8 : 0,
                            shadowColor: _neonCyan.withValues(alpha: 0.5),
                          ),
                          onPressed: busy || (!owned && wallet.coins < item.price)
                              ? null
                              : () async {
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
                                  if (!owned && wallet.ownsCosmetic(item.id)) {
                                    _celebrate(this.context, '${item.name} unlocked!');
                                  }
                                },
                          child: Text(
                            equipped
                                ? 'Take off'
                                : owned
                                    ? 'Wear it'
                                    : 'Unlock · ${item.price}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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
    drawCosmetic(
      c,
      const Size(100, 75),
      const CosmeticFit(head: Offset(.5, .6), neck: Offset(.5, .45), back: Offset(.5, .4), scale: 1),
      item,
    );
    c.restore();
  }
  @override
  bool shouldRepaint(_AccessoryArt old) => old.item.id != item.id;
}
