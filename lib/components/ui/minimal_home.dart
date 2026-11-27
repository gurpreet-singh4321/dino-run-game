import 'package:flutter/material.dart';
import '../../skins/skin.dart';
import 'animated_dino_preview.dart';
import 'adventure_theme.dart';
import 'menu_chrome.dart';
import 'illustrated_menu.dart';
import 'epoch_postcard.dart';
import 'dino_hill_top.dart';
import 'menu_motion.dart';

/// A trailhead: the companion, the destination, then one unmistakable action.
class MinimalHome extends StatelessWidget {
  final CharacterSkin skin;
  final int coins, best, selected, stage;
  final List<String> names;
  final List<IconData> icons;
  final VoidCallback onPlay, onWardrobe, onUpgrades, onJournal, onSettings;
  final VoidCallback? onGift;
  final ValueChanged<int> onSelect;
  final GlobalKey? dinoStageKey;
  final bool showDino;
  const MinimalHome({super.key, required this.skin, required this.coins,
    required this.best, required this.selected, required this.names,
    required this.icons, required this.onPlay, required this.onSelect,
    required this.onWardrobe, required this.onUpgrades, required this.onJournal,
    required this.onSettings, required this.stage, this.onGift,
    this.dinoStageKey, this.showDino = true});

  @override
  Widget build(BuildContext context) {
    double swipe = 0;
    return Theme(data: AdventureTheme.data, child: Material(
      color: Colors.transparent,
      child: Stack(children: [
        Positioned.fill(child: EpochScenery(stage: stage)),
        Positioned.fill(child: CampAtmosphere(stage: stage)),
        SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: LayoutBuilder(builder: (context, outerBounds) {
            final phoneLandscape =
                outerBounds.maxWidth > outerBounds.maxHeight &&
                outerBounds.maxHeight < 430;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: phoneLandscape ? 12 : 16,
                vertical: phoneLandscape ? 4 : 8,
              ),
              child: LayoutBuilder(builder: (context, bounds) {
                final portrait = bounds.maxHeight > bounds.maxWidth;
                final short = bounds.maxHeight < 350;
                final tightWidth = bounds.maxWidth < 560;
                final showInlineTopTitle =
                    !portrait && phoneLandscape && bounds.maxWidth >= 600;
                final toolPad = tightWidth
                    ? const EdgeInsets.fromLTRB(7, 3, 7, 8)
                    : const EdgeInsets.fromLTRB(9, 3, 9, 8);
                Widget tool(String label, MenuSymbol symbol, Color color, VoidCallback? tap) =>
                  Tooltip(message: label, child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: tap, style: adventureButtonStyle(color).copyWith(
                        padding: WidgetStatePropertyAll(toolPad),
                      ),
                      icon: MenuIllustration(symbol, size: tightWidth ? 20 : 22),
                      label: Text(label == 'Daily gift claimed' ? 'Claimed' : label == 'Daily gift' ? 'Gift' : label,
                        style: TextStyle(fontFamily: 'Fredoka', fontSize: tightWidth ? 12.5 : 13)),
                    ),
                  ));
                Widget buildTitleCrest({required bool compact}) {
                  final crest = CustomPaint(
                    painter: _TitleCrestPainter(MenuPalette.accents[stage % MenuPalette.accents.length]),
                    child: Padding(
                      padding: compact
                          ? const EdgeInsets.fromLTRB(16, 4, 16, 9)
                          : const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: compact ? 18.5 : 33,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              shadows: const [Shadow(color: Color(0xEE0D1521), offset: Offset(0, 2.5), blurRadius: 4)],
                            ),
                            children: const [
                              TextSpan(text: 'Dino Run ', style: TextStyle(color: Color(0xFFFFF8E6))),
                              TextSpan(text: 'Epochs', style: TextStyle(color: MenuPalette.gold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  return compact ? SizedBox(height: 46, child: crest) : crest;
                }
                final top = LayoutBuilder(builder: (context, topBounds) {
                  final badge = SizedBox(
                    height: 48,
                    child: CustomPaint(
                      painter: const PlaqueBadgePainter(
                        top: Color(0xFF2D415D),
                        mid: MenuPalette.slate,
                        bottom: Color(0xFF141E2E),
                        outline: Color(0xFF0C1119),
                        lip: Color(0xFF0A1018),
                        innerRim: Color(0xB8C79B50),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MenuIllustration(MenuSymbol.trophy, size: 19),
                            const SizedBox(width: 6),
                            Text('Best $best', style: const TextStyle(color: Colors.white, fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (portrait && topBounds.maxWidth >= 280) {
                    return Row(children: [
                      Expanded(child: FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: badge)),
                      const SizedBox(width: 8),
                      MenuCoinBalance(coins: coins),
                    ]);
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [badge, const SizedBox(width: 8), MenuCoinBalance(coins: coins)],
                      ),
                    ),
                  );
                });
                final tools = Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  tool(onGift == null ? 'Daily gift claimed' : 'Daily gift', MenuSymbol.gift, MenuPalette.terracotta, onGift),
                  SizedBox(width: tightWidth ? 6 : 8),
                  tool('Settings', MenuSymbol.settings, MenuPalette.slate, onSettings),
                ]);
                final dino = LayoutBuilder(builder: (context, box) {
                  final padBottom = portrait
                      ? 8.0
                      : (short ? 10.0 : (box.maxHeight > 440 ? 36.0 : 14.0));
                  final height = (box.maxHeight - padBottom).clamp(
                    60.0,
                    portrait ? 310.0 : 336.0,
                  );
                  final width = height * .86;
                  final ledgeHeight = (height * .26).clamp(28.0, 86.0);
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: padBottom),
                      child: SizedBox(
                        key: dinoStageKey,
                        height: height,
                        width: width,
                        child: Visibility(
                          visible: showDino,
                          maintainState: true,
                          maintainAnimation: true,
                          maintainSize: true,
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
                                child: AnimatedDinoPreview(template: skin, interactive: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                });
                final destination = LayoutBuilder(builder: (context, destBox) {
                  final showTitle = !short && !phoneLandscape && destBox.maxHeight >= 315;
                  final showPrompt = !short && destBox.maxHeight >= 258;
                  final gap = destBox.maxHeight < 205 ? 6.0 : (showTitle ? 12.0 : 8.0);
                  final playHeight = destBox.maxHeight < 200
                      ? 48.0
                      : (phoneLandscape ? 52.0 : 58.0);
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: portrait ? double.infinity : 465),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (showTitle)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: buildTitleCrest(compact: false),
                          ),
                        if (showPrompt)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Where shall we run?',
                              style: TextStyle(
                                color: Color(0xFFFFF4D6),
                                fontFamily: 'Fredoka',
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Color(0xEB0E1826), offset: Offset(0, 2), blurRadius: 8)],
                              ),
                            ),
                          ),
                        Flexible(child: GestureDetector(
                          onHorizontalDragStart: (_) => swipe = 0,
                          onHorizontalDragUpdate: (d) => swipe += d.delta.dx,
                          onHorizontalDragEnd: (d) {
                            final direction = swipe.abs() > 24 ? swipe : (d.primaryVelocity ?? 0);
                            if (swipe.abs() > 24 || direction.abs() > 80) {
                              onSelect((selected + (direction < 0 ? 1 : -1)).clamp(0, names.length - 1));
                            }
                          },
                          child: EpochPostcard(
                            stage: stage,
                            selected: selected,
                            names: names,
                            icon: selected >= 0 && selected < icons.length ? icons[selected] : null,
                            onSelect: onSelect,
                          ),
                        )),
                        SizedBox(height: gap),
                        SizedBox(width: double.infinity, height: playHeight,
                          child: MenuAction(symbol: MenuSymbol.play, label: 'Play',
                            color: const Color(0xFF136C51), prominent: true, showSymbol: false, onPressed: onPlay)),
                      ]),
                    ),
                  );
                });
                Widget secondary(MenuSymbol symbol, String label, Color badgeColor, VoidCallback tap) => Expanded(
                  child: MenuAction(symbol: symbol, label: label, color: MenuPalette.slate, badgeColor: badgeColor, onPressed: tap));
                final secondaryRow = Row(children: [
                  secondary(MenuSymbol.wardrobe, 'Workshop', const Color(0xFFFAE6CD), onWardrobe),
                  SizedBox(width: phoneLandscape ? 8 : 10),
                  secondary(MenuSymbol.upgrades, 'Upgrades', const Color(0xFFDDF3EE), onUpgrades),
                  SizedBox(width: phoneLandscape ? 8 : 10),
                  secondary(MenuSymbol.journal, 'Journal', const Color(0xFFFAF0D4), onJournal),
                ]);
                final wideDock = !portrait && !short && bounds.maxWidth >= 680;
                final narrowLandscapeRatio = !portrait && bounds.maxWidth < 760;
                return Column(children: [
                  if (portrait) ...[top, const SizedBox(height: 6), tools]
                  else Row(children: [
                    Expanded(child: top),
                    if (showInlineTopTitle) ...[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: bounds.maxWidth * 0.34),
                        child: buildTitleCrest(compact: true),
                      ),
                    ],
                    const SizedBox(width: 8),
                    tools,
                  ]),
                  SizedBox(height: phoneLandscape ? 4 : 8),
                  Expanded(child: portrait ? Column(children: [
                    Expanded(child: dino),
                    const SizedBox(height: 12),
                    SizedBox(height: 252, child: destination),
                  ]) : Row(children: [
                    Expanded(flex: narrowLandscapeRatio ? 9 : 5, child: dino),
                    SizedBox(width: phoneLandscape ? 12 : 20),
                    Expanded(flex: narrowLandscapeRatio ? 11 : 5, child: destination),
                  ])),
                  SizedBox(height: phoneLandscape ? 6 : 10),
                  MenuArrival(
                    child: wideDock
                        ? Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 590),
                              child: secondaryRow,
                            ),
                          )
                        : secondaryRow,
                  ),
                ]);
              }),
            );
          }),
        ))),
      ]),
    ));
  }
}

class _TitleCrestPainter extends CustomPainter {
  final Color accent;
  const _TitleCrestPainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final face = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 6.5);
    final p = Paint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(18)),
      p..color = const Color(0xFF141B25),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(1), const Radius.circular(17)),
      p..color = const Color(0xFF4F381E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, const Radius.circular(16)),
      p
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEB273A54), Color(0xF5162336)],
        ).createShader(face),
    );
    p.shader = null;
    canvas.drawRRect(
      RRect.fromRectAndRadius(face.deflate(2.0), const Radius.circular(14)),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(const Color(0xFFD9AE5F), accent, .24)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, face.top + 3.5, size.width - 32, 2.0),
        const Radius.circular(1.5),
      ),
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0x36FFF7DC),
    );
    for (final pt in [
      Offset(face.left + 9, face.top + 9),
      Offset(face.right - 9, face.top + 9),
      Offset(face.left + 9, face.bottom - 9),
      Offset(face.right - 9, face.bottom - 9),
    ]) {
      canvas.drawCircle(pt, 2.1, p..color = const Color(0xFF281D11));
      canvas.drawCircle(
        pt.translate(-0.3, -0.35),
        1.3,
        p..color = const Color(0xFFFFD877),
      );
    }
  }

  @override
  bool shouldRepaint(_TitleCrestPainter old) => old.accent != accent;
}
