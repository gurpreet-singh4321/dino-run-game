import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../game/dino_game.dart';
import '../../managers/audio_manager.dart';
import '../../skins/cart_skins.dart';
import '../../skins/cosmetics.dart';
import '../../skins/skin_registry.dart';
import '../../utils/boot_preview_cache.dart';
import '../../utils/cart_art.dart';
import 'adventure_theme.dart';
import 'adventure_toast.dart';
import 'animated_dino_preview.dart';
import 'dino_hill_top.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';
import 'menu_motion.dart';

class AdventurePanel extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final int? coins;
  final int stage;
  final Color accent;
  final MenuSymbol symbol;
  final double maxWidth, maxHeight;
  final VoidCallback? onClose;
  const AdventurePanel({super.key, required this.title, required this.subtitle,
    required this.child, this.coins, this.onClose, this.stage = 0,
    this.accent = MenuPalette.forest, this.symbol = MenuSymbol.settings,
    this.maxWidth = 900, this.maxHeight = 580});

  @override
  Widget build(BuildContext context) => Theme(
    data: AdventureTheme.forAccent(accent),
    child: Material(color: Colors.transparent, child: Stack(children: [
      Positioned.fill(child: EpochScenery(stage: stage, dim: true)),
      SafeArea(child: LayoutBuilder(builder: (context, safeBounds) {
        final compact = safeBounds.maxHeight < 400;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 4 : 12),
          child: Center(
            child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
              child: MenuPaper(accent: accent, child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ScaffoldMessenger(child: Scaffold(backgroundColor: Colors.transparent,
                  body: Column(children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(accent, const Color(0xFFFFF0C8), .10)!,
                            accent,
                            Color.lerp(accent, const Color(0xFF141C27), .30)!,
                          ],
                          stops: const [0, .55, 1],
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(14, compact ? 5 : 7, 10, compact ? 5 : 7),
                      child: LayoutBuilder(builder: (context, bounds) {
                        final narrow = bounds.maxWidth < 440;
                        return Row(children: [
                          if (!narrow) ...[
                            Container(
                              padding: EdgeInsets.all(compact ? 4 : 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5D9),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFD6A856), width: 1.6),
                                boxShadow: const [BoxShadow(color: Color(0x45121822), offset: Offset(0, 1.5))],
                              ),
                              child: MenuIllustration(symbol, size: compact ? 24 : 28),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontFamily: 'Fredoka',
                                fontSize: narrow ? 20 : (compact ? 21 : 23), fontWeight: FontWeight.w700,
                                shadows: const [Shadow(color: Color(0x66101620), offset: Offset(0, 1.5), blurRadius: 3)])),
                            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xF2FFF6DF), fontWeight: FontWeight.w600)),
                          ])),
                          if (coins != null) ...[const SizedBox(width: 6),
                            ConstrainedBox(constraints: BoxConstraints(maxWidth: narrow ? 96 : 150),
                              child: MenuCoinBalance(coins: coins!))],
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: Tooltip(message: 'Close panel', child: FilledButton(
                              style: adventureButtonStyle(MenuPalette.red).copyWith(
                                padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(11, 3, 11, 8))),
                              onPressed: onClose ?? () => Navigator.pop(context),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                MenuIllustration(MenuSymbol.close, size: 17), SizedBox(width: 4), Text('Close'),
                              ]))),
                          ),
                        ]);
                      }),
                    ),
                    Container(
                      height: 3.5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB5863E), Color(0xFFF6D688), Color(0xFFB5863E)],
                        ),
                        border: Border(bottom: BorderSide(color: Color(0xFF4F381E), width: 1.2)),
                      ),
                    ),
                    Expanded(child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 6 : 10),
                      child: child,
                    )),
                  ])),
                )),
              )),
            ),
          );
      })),
    ])),
  );
}

void _celebrate(BuildContext context, String message) {
  AudioManager.playUpgrade();
  showAdventureToast(context, message);
}

class AdventureUpgrades extends StatefulWidget {
  final DinoGame game;
  const AdventureUpgrades({super.key, required this.game});
  @override
  State<AdventureUpgrades> createState() => _AdventureUpgradesState();
}

class _AdventureUpgradesState extends State<AdventureUpgrades> {
  @override
  Widget build(BuildContext context) => AdventurePanel(
    title: 'Upgrades', accent: MenuPalette.teal, symbol: MenuSymbol.upgrades,
    subtitle: 'Choose a power to improve.', stage: widget.game.biomeManager.currentStage,
    coins: widget.game.coinManager.coins,
    child: _WorkshopUpgrades(game: widget.game, onChanged: () => setState(() {})),
  );
}

class AdventureWardrobe extends StatefulWidget {
  final DinoGame game;
  const AdventureWardrobe({super.key, required this.game});
  @override
  State<AdventureWardrobe> createState() => _AdventureWardrobeState();
}

class _AdventureWardrobeState extends State<AdventureWardrobe> {
  bool busy = false;
  int tab = 0, equipReaction = 0;
  CosmeticSlot slot = CosmeticSlot.head;
  late String selected;
  late String cartSelected;

  @override
  void initState() {
    super.initState();
    final wallet = widget.game.coinManager;
    selected =
        wallet.equippedCosmetics[slot] ??
        CosmeticCatalog.items.firstWhere((i) => i.slot == slot).id;
    cartSelected = wallet.equippedCartSkin;
  }

  Future<void> act(BuildContext context, {required bool owned, required bool equipped}) async {
    if (busy || equipped) return;
    setState(() => busy = true);
    final wallet = widget.game.coinManager;
    try {
      final ok = tab == 1
        ? (owned ? await wallet.equipCartSkin(cartSelected) : await wallet.purchaseCartSkin(cartSelected))
        : (owned ? await wallet.equipCosmetic(selected) : await wallet.purchaseCosmetic(selected));
      if (owned && ok) {
        if (mounted) setState(() => equipReaction++);
        SkinRegistry.setCosmetics(wallet.equippedCosmetics.values);
        if (tab == 0) {
          unawaited(cacheBootStagePreview(SkinRegistry.defaultSkin));
        }
      }
      if (context.mounted) {
        if (ok) {
          _celebrate(context, owned ? 'Equipped for your next adventure' : 'Unlocked! Equip when you are ready.');
        } else {
          showAdventureToast(context, 'Could not unlock this item');
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> takeOff(CosmeticSlot itemSlot) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.game.coinManager.removeCosmetic(itemSlot);
      SkinRegistry.setCosmetics(widget.game.coinManager.equippedCosmetics.values);
      unawaited(cacheBootStagePreview(SkinRegistry.defaultSkin));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.game.coinManager;
    final cart = CartSkinCatalog.find(cartSelected)!;
    final item = CosmeticCatalog.find(selected)!;
    final owned = tab == 1 ? wallet.ownsCartSkin(cart.id) : wallet.ownsCosmetic(item.id);
    final equipped = tab == 1 ? wallet.equippedCartSkin == cart.id : wallet.equippedCosmetics[item.slot] == item.id;
    final price = tab == 1 ? cart.price : item.price;
    final preview = SkinRegistry.createInstance('new_dino');
    final outfit = Map<CosmeticSlot, String>.from(wallet.equippedCosmetics);
    if (tab == 0) outfit[item.slot] = item.id;
    preview.cosmetics = outfit.values.map((id) => CosmeticCatalog.find(id)!).toList();
    final tabs = LayoutBuilder(builder: (context, tabBounds) {
      final pill = Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD9C298), Color(0xFFEBDAC0)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFAE8E5B), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x20FFFFFF), offset: Offset(0, 1))],
        ),
        child: Row(children: [
          for (final entry in [(0, 'Outfits'), (1, 'Carts')])
            Expanded(child: Semantics(button: true, selected: tab == entry.$1, child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                gradient: tab == entry.$1
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFFEFA), Color(0xFFF9EED8)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
                border: tab == entry.$1 ? Border.all(color: const Color(0xFFC59F62), width: 1.3) : null,
                boxShadow: tab == entry.$1
                    ? const [BoxShadow(color: Color(0x38422E17), offset: Offset(0, 2))]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: busy ? null : () => setState(() => tab = entry.$1),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(entry.$2, textAlign: TextAlign.center, style: TextStyle(
                          fontFamily: 'Fredoka', fontSize: 15,
                          fontWeight: tab == entry.$1 ? FontWeight.w800 : FontWeight.w600,
                          color: tab == entry.$1 ? MenuPalette.terracotta : MenuPalette.ink,
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ))),
        ]),
      );
      return tabBounds.maxWidth > 320 ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340), child: pill)) : pill;
    });
    final action = Builder(builder: (localContext) => SizedBox(width: double.infinity,
      child: FilledButton(
        onPressed: busy || equipped || (!owned && wallet.coins < price) ? null : () => act(localContext, owned: owned, equipped: equipped),
        child: Text(busy ? 'Saving…' : equipped ? 'Equipped' : owned ? 'Equip'
          : wallet.coins < price ? 'Need ${price - wallet.coins} more coins' : 'Unlock · $price coins',
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      )));
    return AdventurePanel(
      title: 'Workshop', subtitle: 'Try it on. Make it yours.', accent: MenuPalette.terracotta,
      symbol: MenuSymbol.wardrobe, stage: widget.game.biomeManager.currentStage, coins: wallet.coins,
      child: LayoutBuilder(builder: (context, bounds) {
        final compact = bounds.maxHeight < 300 || bounds.maxWidth < 660;
        final stage = widget.game.biomeManager.currentStage;
        final hasEquippedSlot =
            tab == 0 && wallet.equippedCosmetics.containsKey(item.slot);
        final previewArt = Expanded(child: LayoutBuilder(builder: (context, box) {
          final padBottom = compact ? 10.0 : 18.0;
          final availableH = math.max(56.0, box.maxHeight - padBottom);
          final height = math.min(availableH, box.maxWidth * (tab == 1 && !compact ? 1.0 : 1.18));
          final width = tab == 1 && !compact
              ? math.min(box.maxWidth, height * 1.1)
              : height / 1.2;
          final ledgeHeight = (height * .26).clamp(22.0, 68.0);
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: padBottom),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: -ledgeHeight * .50,
                      width: width * 1.54,
                      height: ledgeHeight,
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(painter: DinoHillTopPainter(stage)),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: AnimatedDinoPreview(
                        template: preview,
                        equipReaction: equipReaction,
                        cartSkinId: tab == 1 ? cart.id : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }));
        final takeOffButton = SizedBox(
          height: compact ? 32 : 36,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF2D6),
              foregroundColor: MenuPalette.terracotta,
              disabledForegroundColor: MenuPalette.muted,
              side: const BorderSide(color: Color(0xFFC25831), width: 1.5),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 4),
              minimumSize: Size(0, compact ? 32 : 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: busy ? null : () => takeOff(item.slot),
            child: Text(
              'Take off',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        final previewMeta = Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tab == 1 ? cart.name : item.name, textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Fredoka', fontSize: compact ? 14 : 16, fontWeight: FontWeight.w700, color: MenuPalette.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (!compact && tab == 1) const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('Smashes 3 objects.\nSkins change appearance.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: MenuPalette.muted)),
          ),
          if (hasEquippedSlot) ...[
            SizedBox(height: compact ? 4 : 6),
            takeOffButton,
          ],
        ]);
        final showcaseCard = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB5925A), width: 1.8),
            boxShadow: const [
              BoxShadow(color: Color(0x2B49351C), offset: Offset(0, 2.5)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: _ShowcaseStagePainter(stage),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 8 : 12,
                  compact ? 6 : 12,
                  compact ? 8 : 12,
                  compact ? 6 : 10,
                ),
                child: Column(children: [
                  previewArt,
                  SizedBox(height: compact ? 4 : 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: compact ? 5 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xEBFFFBF0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6BB8E), width: 1.2),
                    ),
                    child: previewMeta,
                  ),
                ]),
              ),
            ),
          ),
        );
        final previewCol = Expanded(
          flex: compact ? 4 : 5,
          child: compact
              ? Column(children: [
                  tabs,
                  const SizedBox(height: 5),
                  Expanded(child: showcaseCard),
                ])
              : showcaseCard,
        );
        final catalogCol = Expanded(flex: compact ? 6 : 7, child: Column(children: [
          if (!compact) ...[tabs, const SizedBox(height: 8)],
          if (tab == 0) Padding(padding: EdgeInsets.only(bottom: compact ? 5 : 8), child: Row(children: [
            for (final filter in CosmeticSlot.values)
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Semantics(selected: slot == filter, child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size(44, compact ? 40 : 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: slot == filter ? MenuPalette.terracotta : const Color(0xFFF3E7CF),
                    foregroundColor: slot == filter ? Colors.white : MenuPalette.ink,
                    side: BorderSide(
                      color: slot == filter ? const Color(0xFF7D3116) : const Color(0xFFCEB588),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  onPressed: busy ? null : () => setState(() {
                    slot = filter;
                    selected = wallet.equippedCosmetics[slot] ??
                        CosmeticCatalog.items.firstWhere((i) => i.slot == slot).id;
                  }),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${filter.name[0].toUpperCase()}${filter.name.substring(1)}',
                      style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600)),
                  ),
                )))),
          ])),
          Expanded(child: _WorkshopShelf(
            key: ValueKey('$tab-${slot.name}'),
            compact: compact,
            children: [
              if (tab == 0) for (final candidate in CosmeticCatalog.items.where((i) => i.slot == slot))
                _WorkshopChoice(name: candidate.name,
                  detail: wallet.ownsCosmetic(candidate.id) ? 'Owned' : '${candidate.price} coins',
                  selected: selected == candidate.id,
                  art: CustomPaint(painter: _AccessoryArt(candidate)),
                  onTap: busy ? null : () => setState(() => selected = candidate.id)),
              if (tab == 1) for (final candidate in CartSkinCatalog.items)
                _WorkshopChoice(name: candidate.name,
                  detail: wallet.ownsCartSkin(candidate.id) ? 'Owned' : '${candidate.price} coins',
                  selected: cartSelected == candidate.id,
                  grounded: true,
                  art: CustomPaint(painter: _CartThumbnail(candidate.id)),
                  onTap: busy ? null : () => setState(() => cartSelected = candidate.id)),
            ],
          )),
          SizedBox(height: compact ? 5 : 8),
          SizedBox(height: compact ? 44 : 48, child: action),
        ]));
        return Row(children: [previewCol, SizedBox(width: compact ? 10 : 14), catalogCol]);
      }),
    );
  }
}

class _WorkshopShelf extends StatelessWidget {
  final List<Widget> children;
  final bool compact;
  const _WorkshopShelf({super.key, required this.children, this.compact = false});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final gap = compact ? 8.0 : 10.0;
      final singleRow = bounds.maxHeight < 210 || compact;
      final rowCount = singleRow ? 1 : 2;
      final rowHeight = math.max(
        96.0,
        (bounds.maxHeight - gap * (rowCount - 1)) / rowCount,
      );
      final cardWidth = singleRow
          ? (bounds.maxWidth * 0.44).clamp(112.0, 152.0)
          : ((bounds.maxWidth - gap) / 2.15).clamp(136.0, 184.0);
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rowCount,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: rowHeight / cardWidth,
          ),
          itemBuilder: (_, index) => children[index],
        ),
      );
    },
  );
}

class _WorkshopChoice extends StatelessWidget {
  final String name, detail;
  final bool selected, grounded;
  final Widget art;
  final VoidCallback? onTap;
  const _WorkshopChoice({required this.name, required this.detail, required this.selected, required this.art, this.grounded = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final isOwned = detail == 'Owned';
    return Semantics(selected: selected,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [Color(0xFFFFFAEB), Color(0xFFFFEFC7)]
                : const [Color(0xFFFFFDF8), Color(0xFFF6EAD1)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? MenuPalette.terracotta : const Color(0xFFCEB58B),
            width: selected ? 2.4 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? const Color(0x45A84723) : const Color(0x28574023),
              offset: const Offset(0, 2.5),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: MenuInkAction(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selected
                          ? const [Color(0xFFFFF7E1), Color(0xFFF8E5B8)]
                          : const [Color(0xFFFAF2DF), Color(0xFFEEE0C3)],
                    ),
                    border: Border.all(
                      color: selected ? const Color(0x55C25831) : const Color(0x44B49768),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Stack(children: [
                    if (grounded)
                      Positioned(
                        left: 0, right: 0, bottom: 0, height: 14,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: selected ? const Color(0x33D69F4E) : const Color(0x28A98B5A),
                          ),
                        ),
                      ),
                    Positioned.fill(child: ClipRect(child: art)),
                    if (selected)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: MenuPalette.emerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFF3C6), width: 1.4),
                            boxShadow: const [BoxShadow(color: Color(0x45122019), offset: Offset(0, 1.5))],
                          ),
                          child: const MenuCheckmark(size: 12),
                        ),
                      ),
                  ]),
                ),
              )),
              const SizedBox(height: 5),
              Text(name, maxLines: 1, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w700, color: MenuPalette.ink)),
              const SizedBox(height: 2),
              Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, height: 1.1, fontWeight: FontWeight.w700,
                  color: isOwned ? MenuPalette.emerald : MenuPalette.muted)),
            ]),
          )),
        ),
      ),
    );
  }
}

class _ShowcaseStagePainter extends CustomPainter {
  final int stage;
  const _ShowcaseStagePainter(this.stage);
  @override
  void paint(Canvas canvas, Size size) {
    final tint = MenuPalette.accents[stage % MenuPalette.accents.length];
    final rect = Offset.zero & size;
    final p = Paint();
    canvas.drawRect(
      rect,
      p
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFFFF6DF), tint, .16)!,
            const Color(0xFFFBF0DA),
            Color.lerp(const Color(0xFFEAD3AE), tint, .10)!,
          ],
          stops: const [0, .58, 1],
        ).createShader(rect),
    );
    p.shader = null;
    // Soft sky halo behind Dino / cart showcase while DinoHillTopPainter renders the foreground earth mound.
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .38),
      size.shortestSide * .42,
      p..color = const Color(0x70FFFDF4),
    );
    // Distant silhouetted dunes/hills behind the foreground hilltop.
    final horizon = size.height * .66;
    final hill = Path()
      ..moveTo(0, horizon + 12)
      ..quadraticBezierTo(size.width * .28, horizon - 14, size.width * .55, horizon + 4)
      ..quadraticBezierTo(size.width * .82, horizon - 10, size.width, horizon + 6)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, p..color = Color.lerp(const Color(0xFFE3C89D), tint, .12)!.withValues(alpha: .65));
  }

  @override
  bool shouldRepaint(_ShowcaseStagePainter old) => old.stage != stage;
}

class _CartThumbnail extends CustomPainter {
  final String id;
  _CartThumbnail(this.id);
  @override
  void paint(Canvas c, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    c.save();
    c.clipRect(Offset.zero & size);
    const w = 103.0, h = 47.0;
    final scale = math.min(size.width / w, size.height / h) * .92;
    c.translate((size.width - w * scale) / 2, (size.height - h * scale) / 2 - 3.1 * scale);
    c.scale(scale);
    CartArt.rear(c, skinId: id);
    CartArt.front(c, charges: 3, distance: 0, skinId: id);
    c.restore();
  }
  @override
  bool shouldRepaint(_CartThumbnail old) => old.id != id;
}

class _WorkshopUpgrades extends StatefulWidget {
  final DinoGame game;
  final VoidCallback onChanged;
  const _WorkshopUpgrades({required this.game, required this.onChanged});
  @override
  State<_WorkshopUpgrades> createState() => _WorkshopUpgradesState();
}
class _WorkshopUpgradesState extends State<_WorkshopUpgrades> {
  String? saving;
  static const powers = [
    ('magnet', 'Coin magnet', 'Bring nearby coins closer.'),
    ('shield', 'Bubble shield', 'Extra shield duration.'),
    ('cosmic', 'Star rocket', 'Earn more score during space flights.'),
    ('multiplier', 'Lucky stars', 'More double-coin surprises.'),
  ];
  String benefit(String id, int level) {
    final next = math.min(level + 1, 5);
    return switch (id) {
      'magnet' || 'shield' => level == 5 ? '${8 + level * 2}s duration · Max' : '${8 + level * 2}s to ${8 + next * 2}s duration',
      'cosmic' => level == 5 ? '+${level * 40}% flight score · Max' : '+${level * 40}% to +${next * 40}% flight score',
      _ => level == 5 ? '${level * 20}% double-coin chance · Max' : '${level * 20}% to ${next * 20}% double-coin chance',
    };
  }
  @override
  Widget build(BuildContext context) => ListView.separated(itemCount: powers.length,
    padding: const EdgeInsets.symmetric(vertical: 2),
    separatorBuilder: (_, _) => const SizedBox(height: 7),
    itemBuilder: (context, index) {
      final entry = powers[index], wallet = widget.game.coinManager;
      final level = wallet.getUpgradeLevel(entry.$1);
      final price = level >= 5 ? 0 : [500, 1000, 2500, 5000, 10000][level];
      final shortfall = price - wallet.coins;
      final accent = [MenuPalette.orange, MenuPalette.blue, MenuPalette.violet, MenuPalette.forest][index];
      final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.$2, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 18, color: MenuPalette.ink)),
        const SizedBox(height: 2), Text(entry.$3, style: const TextStyle(fontSize: 13.5, height: 1.2, color: MenuPalette.muted)),
        const SizedBox(height: 4), Text(benefit(entry.$1, level), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MenuPalette.ink)),
        const SizedBox(height: 6),
        Semantics(label: 'Level $level of 5', excludeSemantics: true, child: Row(children: [
          for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(right: 4),
            child: Container(width: 16, height: 9, decoration: BoxDecoration(
              color: i < level ? accent : const Color(0xFFE3D8C2),
              border: Border.all(
                color: i < level ? Color.lerp(accent, Colors.black, .35)! : const Color(0xFFBFAE8E),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(3.5)))),
          Flexible(child: Text('$level / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MenuPalette.ink))),
        ])),
      ]);
      final action = SizedBox(width: 128, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Tooltip(message: shortfall > 0 ? 'Need $shortfall more coins' : 'Upgrade ${entry.$2}', child: FilledButton(
          style: adventureButtonStyle(accent),
          onPressed: level >= 5 || shortfall > 0 || saving != null ? null : () async {
            if (saving != null) return;
            setState(() => saving = entry.$1);
            try {
              final upgraded = wallet.upgradePowerup(entry.$1, price);
              widget.onChanged(); await wallet.forceSave();
              if (upgraded && context.mounted) _celebrate(context, '${entry.$2} upgraded');
            } finally { if (mounted) setState(() => saving = null); }
          },
          child: Text(level >= 5 ? 'Max level' : saving == entry.$1 ? 'Saving…' : '$price coins',
            textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16)),
        )),
        if (level < 5 && shortfall > 0) Padding(padding: const EdgeInsets.only(top: 4),
          child: Text('Need $shortfall more', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: MenuPalette.muted, fontWeight: FontWeight.w600))),
      ]));
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF6), Color(0xFFF6EAD1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCEB589), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x26543E22), offset: Offset(0, 2.5))],
        ),
        child: LayoutBuilder(builder: (context, bounds) {
          final narrow = bounds.maxWidth < 430 || MediaQuery.textScalerOf(context).scale(14) > 19;
          return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52, height: 54,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFDFC0),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFCBB082), width: 1.4),
                ),
                child: CustomPaint(painter: _BoostArt(index)),
              ),
              const SizedBox(width: 12), Expanded(child: details),
              if (!narrow) ...[const SizedBox(width: 16), action],
            ]),
            if (narrow) ...[const SizedBox(height: 8), action],
          ]);
        }),
      );
    },
  );
}

class AdventureJournal extends StatefulWidget {
  final DinoGame game;
  const AdventureJournal({super.key, required this.game});
  @override
  State<AdventureJournal> createState() => _AdventureJournalState();
}
class _AdventureJournalState extends State<AdventureJournal> {
  int? saving;
  @override
  Widget build(BuildContext context) {
    final wallet = widget.game.coinManager;
    const names = ['Collect 50 coins', 'Reach a best score of 500', 'Absorb 3 hits with a shield', 'Make 10 jumps', 'Take a trip to space'];
    const targets = [50, 500, 3, 10, 1], rewards = [50, 100, 80, 60, 120];
    final values = [wallet.collectedCoins, wallet.highScore, wallet.shieldHits, wallet.totalJumps, wallet.spaceTrips];
    return AdventurePanel(title: 'Epoch journal', accent: MenuPalette.blue, symbol: MenuSymbol.journal,
      subtitle: 'Your discoveries, one run at a time.', coins: wallet.coins, stage: widget.game.biomeManager.currentStage,
      child: ListView.separated(itemCount: names.length + 1,
        padding: const EdgeInsets.symmetric(vertical: 2),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, row) {
          if (row == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF283B55), Color(0xFF192639)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCFA55C), width: 1.6),
                boxShadow: const [BoxShadow(color: Color(0x35101824), offset: Offset(0, 2))],
              ),
              child: Row(children: [
                const MenuIllustration(MenuSymbol.trophy, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Your best adventure · ${wallet.highScore}',
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white))),
              ]),
            );
          }
          final index = row - 1;
          final claimed = wallet.isMissionClaimed(index);
          final ready = values[index] >= targets[index] && !claimed;
          final progress = math.min(values[index], targets[index]);
          final detail = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(names[index], style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 17, color: MenuPalette.ink)),
            const SizedBox(height: 4),
            Text(claimed ? 'Discovery recorded' : ready ? 'Ready to collect!' : '$progress / ${targets[index]} · In progress',
              style: TextStyle(fontSize: 13, color: ready ? MenuPalette.forest : MenuPalette.muted,
                fontWeight: ready ? FontWeight.w800 : FontWeight.w600)),
            const SizedBox(height: 7),
            Semantics(
              label: '$progress of ${targets[index]}',
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7D8BC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC4B08B), width: 1),
                ),
                child: LinearProgressIndicator(
                  value: (values[index] / targets[index]).clamp(0, 1),
                  minHeight: 6,
                  color: claimed ? MenuPalette.forest : MenuPalette.blue,
                  backgroundColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ]);
          final action = SizedBox(width: 128, height: 56, child: FilledButton(
            style: adventureButtonStyle(claimed ? MenuPalette.forest : MenuPalette.blue).copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(48, 56)),
              padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(8, 3, 8, 8)),
            ),
            onPressed: !ready || saving != null ? null : () async {
              if (saving != null) return;
              setState(() => saving = index);
              wallet.claimMission(index, rewards[index]);
              try {
                await wallet.forceSave();
                if (context.mounted) _celebrate(context, 'Discovery recorded · +${rewards[index]} coins');
              } finally { if (mounted) setState(() => saving = null); }
            },
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(saving == index ? 'Saving…' : claimed ? 'Collected' : 'Claim\n${rewards[index]} coins',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w800)),
              ),
            ),
          ));
          return Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFCF6), Color(0xFFF6EAD1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ready ? MenuPalette.emerald : const Color(0xFFCEB589),
                width: ready ? 2.0 : 1.5,
              ),
              boxShadow: const [BoxShadow(color: Color(0x26543E22), offset: Offset(0, 2.5))],
            ),
            child: LayoutBuilder(builder: (context, bounds) {
              final narrow = bounds.maxWidth < 420 || MediaQuery.textScalerOf(context).scale(14) > 19;
              return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 56, height: 56,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFDFC0),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFCBB082), width: 1.4),
                    ),
                    child: CustomPaint(painter: _JournalArt(index)),
                  ),
                  const SizedBox(width: 12), Expanded(child: detail),
                  if (!narrow) ...[const SizedBox(width: 14), action],
                ]),
                if (narrow) ...[const SizedBox(height: 10), action],
              ]);
            }),
          );
        },
      ),
    );
  }
}

class _JournalArt extends CustomPainter {
  final int index;
  _JournalArt(this.index);
  @override
  void paint(Canvas c, Size size) {
    if (index == 0) { _BoostArt(3).paint(c, size); return; }
    if (index == 2) { _BoostArt(1).paint(c, size); return; }
    if (index == 4) { _BoostArt(2).paint(c, size); return; }
    final p = Paint();
    c.drawOval(const Rect.fromLTWH(3, 43, 43, 6), p..color = const Color(0x22785131));
    if (index == 1) {
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 7, 5, 37), const Radius.circular(2)), p..color = const Color(0xFF9D744B));
      c.drawPath(Path()..moveTo(17, 8)..quadraticBezierTo(28, 2, 40, 9)..lineTo(40, 27)..quadraticBezierTo(28, 19, 17, 25)..close(), p..color = MenuPalette.coral);
      c.drawPath(Path()..moveTo(19, 10)..quadraticBezierTo(28, 7, 36, 10), p..color = const Color(0xFFFFC994)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    } else {
      c.drawPath(Path()..moveTo(3, 43)..lineTo(15, 26)..quadraticBezierTo(20, 24, 23, 28)..lineTo(33, 42)..close(), p..color = const Color(0xFFAB7F48));
      c.drawPath(Path()..moveTo(10, 43)..lineTo(23, 12)..quadraticBezierTo(26, 8, 31, 15)..lineTo(45, 43)..close(), p..color = const Color(0xFFD8AB66));
      c.drawPath(Path()..moveTo(21, 18)..lineTo(27, 10)..lineTo(34, 23)..lineTo(27, 20)..close(), p..color = const Color(0xFFFFDF98));
      c.drawPath(Path()..moveTo(6, 22)..quadraticBezierTo(13, 9, 19, 8), p..color = MenuPalette.forest..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
      c.drawPath(Path()..moveTo(12, 8)..lineTo(19, 8)..lineTo(18, 15), p);
    }
  }
  @override
  bool shouldRepaint(_JournalArt old) => old.index != index;
}

class _AccessoryArt extends CustomPainter {
  final CosmeticItem item;
  _AccessoryArt(this.item);
  @override
  void paint(Canvas c, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    c.save();
    c.clipRect(Offset.zero & size);
    final scale = math.min(size.width / 100, size.height / 75) * .9;
    c.translate((size.width - 100 * scale) / 2, (size.height - 75 * scale) / 2);
    c.scale(scale);
    drawCosmetic(c, const Size(100, 75), const CosmeticFit(head: Offset(.5, .62),
      neck: Offset(.5, .46), back: Offset(.5, .42), scale: .78), item);
    c.restore();
  }
  @override
  bool shouldRepaint(_AccessoryArt old) => old.item.id != item.id;
}

class _BoostArt extends CustomPainter {
  final int index;
  _BoostArt(this.index);
  @override
  void paint(Canvas c, Size size) {
    c.save(); c.translate((size.width - 56) / 2, (size.height - 56) / 2);
    final p = Paint();
    if (index == 0) {
      c.drawPath(Path()..moveTo(13, 13)..lineTo(13, 29)..cubicTo(13, 51, 43, 51, 43, 29)..lineTo(43, 13),
        p..color = const Color(0xFFBD5342)..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round);
      p.style = PaintingStyle.fill;
      for (final x in [7.0, 37.0]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 8, 12, 12), const Radius.circular(3)), p..color = const Color(0xFFB9C6C2));
      }
    } else if (index == 1) {
      c.drawCircle(const Offset(28, 28), 22, p..shader = const RadialGradient(colors: [Color(0x558BE0CA), Color(0xFF6DB7AF)]).createShader(const Rect.fromLTWH(6, 6, 44, 44)));
      p.shader = null;
      c.drawArc(const Rect.fromLTWH(13, 12, 29, 29), 3.4, 1.1, false, p..color = const Color(0xDDFFF8DB)..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
    } else if (index == 2) {
      c.drawPath(Path()..moveTo(21, 37)..lineTo(28, 55)..lineTo(36, 37)..close(), p..color = MenuPalette.gold);
      c.drawPath(Path()..moveTo(18, 36)..quadraticBezierTo(15, 12, 28, 3)..quadraticBezierTo(42, 12, 38, 36)..close(), p..color = const Color(0xFFBD5342));
      c.drawCircle(const Offset(28, 23), 7, p..color = const Color(0xFFB9D9D8));
      c.drawCircle(const Offset(26, 21), 2, p..color = const Color(0xFFFFF8DB));
    } else {
      for (final offset in [const Offset(19, 31), const Offset(36, 23)]) {
        c.drawCircle(offset + const Offset(0, 2), 13, p..color = const Color(0xFFAD7D30));
        c.drawCircle(offset, 13, p..color = MenuPalette.gold);
        c.drawCircle(offset, 9, p..color = const Color(0xFFC58B31)..style = PaintingStyle.stroke..strokeWidth = 1);
        p.style = PaintingStyle.fill;
      }
    }
    c.restore();
  }
  @override
  bool shouldRepaint(_BoostArt old) => old.index != index;
}
