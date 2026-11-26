import 'package:flutter/material.dart';
import '../../skins/skin.dart';
import 'animated_dino_preview.dart';
import 'adventure_theme.dart';
import 'menu_chrome.dart';
import 'illustrated_menu.dart';
import 'epoch_postcard.dart';
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
  const MinimalHome({super.key, required this.skin, required this.coins,
    required this.best, required this.selected, required this.names,
    required this.icons, required this.onPlay, required this.onSelect,
    required this.onWardrobe, required this.onUpgrades, required this.onJournal,
    required this.onSettings, required this.stage, this.onGift});

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
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(builder: (context, bounds) {
              final portrait = bounds.maxHeight > bounds.maxWidth;
              final short = bounds.maxHeight < 350;
              Widget tool(String label, MenuSymbol symbol, Color color, VoidCallback? tap) =>
                Tooltip(message: label, child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: tap, style: adventureButtonStyle(color).copyWith(
                      padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(9, 3, 9, 8)),
                    ),
                    icon: MenuIllustration(symbol, size: 22),
                    label: Text(label == 'Daily gift claimed' ? 'Claimed' : label == 'Daily gift' ? 'Gift' : label,
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13)),
                  ),
                ));
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
                const SizedBox(width: 8),
                tool('Settings', MenuSymbol.settings, MenuPalette.slate, onSettings),
              ]);
              final dino = LayoutBuilder(builder: (context, box) {
                final height = box.maxHeight.clamp(60.0, portrait ? 310.0 : 340.0);
                final width = height * .86;
                final ledgeHeight = (height * .20).clamp(20.0, 56.0);
                final padBottom = portrait || short ? 8.0 : 20.0;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: padBottom),
                    child: SizedBox(
                      height: height,
                      width: width,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: -ledgeHeight * .44,
                            width: width * 1.24,
                            height: ledgeHeight,
                            child: IgnorePointer(
                              child: CustomPaint(painter: _DinoTrailLedgePainter(stage)),
                            ),
                          ),
                          Positioned.fill(
                            child: AnimatedDinoPreview(template: skin, interactive: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
              final destination = LayoutBuilder(builder: (context, destBox) {
                final showTitle = !short && destBox.maxHeight >= 315;
                final showPrompt = !short && destBox.maxHeight >= 258;
                final gap = destBox.maxHeight < 200 ? 6.0 : (showTitle ? 12.0 : 10.0);
                final playHeight = destBox.maxHeight < 200 ? 50.0 : (short ? 52.0 : 58.0);
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: portrait ? double.infinity : 465),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (showTitle)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: CustomPaint(
                            painter: _TitleCrestPainter(MenuPalette.accents[stage % MenuPalette.accents.length]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 33,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      shadows: [Shadow(color: Color(0xEE0D1521), offset: Offset(0, 2.5), blurRadius: 4)],
                                    ),
                                    children: [
                                      TextSpan(text: 'Dino Run ', style: TextStyle(color: Color(0xFFFFF8E6))),
                                      TextSpan(text: 'Epochs', style: TextStyle(color: MenuPalette.gold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                const SizedBox(width: 10),
                secondary(MenuSymbol.upgrades, 'Upgrades', const Color(0xFFDDF3EE), onUpgrades),
                const SizedBox(width: 10),
                secondary(MenuSymbol.journal, 'Journal', const Color(0xFFFAF0D4), onJournal),
              ]);
              final wideDock = !portrait && !short && bounds.maxWidth >= 680;
              return Column(children: [
                if (portrait) ...[top, const SizedBox(height: 6), tools]
                else Row(children: [Expanded(child: top), const SizedBox(width: 8), tools]),
                const SizedBox(height: 8),
                Expanded(child: portrait ? Column(children: [
                  Expanded(child: dino),
                  const SizedBox(height: 12),
                  SizedBox(height: 252, child: destination),
                ]) : Row(children: [
                  Expanded(flex: 5, child: dino),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: destination),
                ])),
                const SizedBox(height: 10),
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
          ),
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

class _DinoTrailLedgePainter extends CustomPainter {
  final int stage;
  const _DinoTrailLedgePainter(this.stage);

  static const _palettes = [
    // 0: Desert sandstone
    (Color(0xFFB5824E), Color(0xFF6B4727), Color(0xFFFFE5B0), Color(0xFFD6A870)),
    // 1: Monsoon wet mossy slate & puddle
    (Color(0xFF426A6C), Color(0xFF21383D), Color(0xFFAEEBFF), Color(0xFF6BA6AE)),
    // 2: Forest mossy turf & grass
    (Color(0xFF469553), Color(0xFF255233), Color(0xFFC5F49E), Color(0xFF7FD171)),
    // 3: Glacial snow & ice slab
    (Color(0xFFD4F1FF), Color(0xFF619EC4), Color(0xFFFFFFFF), Color(0xFF9CD8F5)),
    // 4: Volcanic charred basalt & magma glow
    (Color(0xFF4A3539), Color(0xFF1E1418), Color(0xFFFF8C42), Color(0xFFFF5924)),
    // 5: Cosmic moon rock & stardust
    (Color(0xFF5A549E), Color(0xFF252152), Color(0xFFB7C4FF), Color(0xFF8BE8FF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = stage % 6;
    final (topColor, bodyColor, crestColor, detailColor) = _palettes[s];
    const deepColor = Color(0xFF141820);
    final ground = Rect.fromLTWH(0, size.height * .22, size.width, size.height * .78);
    final p = Paint();
    // Soft ambient shadow dispersing into the painted landscape below.
    canvas.drawOval(
      Rect.fromLTWH(size.width * .02, size.height * .46, size.width * .96, size.height * .54),
      p
        ..shader = const RadialGradient(
          colors: [Color(0xAD0A1019), Color(0x4A0A1019), Color(0x000A1019)],
          stops: [0, .62, 1],
        ).createShader(ground),
    );
    p.shader = null;

    // Ground mound silhouette rooted beneath Dino's soles.
    final path = Path()
      ..moveTo(size.width * .08, size.height * .66)
      ..quadraticBezierTo(size.width * .20, size.height * .26, size.width * .50, size.height * .27)
      ..quadraticBezierTo(size.width * .80, size.height * .26, size.width * .92, size.height * .66)
      ..quadraticBezierTo(size.width * .50, size.height * .82, size.width * .08, size.height * .66)
      ..close();
    canvas.drawPath(
      path,
      p
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topColor.withValues(alpha: 0.94),
            bodyColor.withValues(alpha: 0.90),
            deepColor.withValues(alpha: 0.0),
          ],
          stops: const [0, .58, 1],
        ).createShader(ground),
    );
    p.shader = null;

    // Epoch-specific ground surface texture clipped cleanly inside the mound.
    canvas.save();
    canvas.clipPath(path);
    switch (s) {
      case 0: // Desert: sandstone strata & pebbles
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * .42, size.height * .44),
            width: size.width * .42,
            height: size.height * .12,
          ),
          p..color = detailColor.withValues(alpha: .28),
        );
        for (final g in [
          (0.22, 0.56, 4.2, 2.0),
          (0.75, 0.53, 4.5, 2.1),
          (0.35, 0.65, 3.0, 1.5),
          (0.65, 0.63, 3.2, 1.6),
        ]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(size.width * g.$1, size.height * g.$2),
              width: g.$3 * 2,
              height: g.$4 * 2,
            ),
            p..color = detailColor.withValues(alpha: .58),
          );
        }
      case 1: // Monsoon: glossy wet puddle sheen & rain ripples
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * .54, size.height * .52),
            width: size.width * .52,
            height: size.height * .22,
          ),
          p
            ..shader = LinearGradient(
              colors: [
                const Color(0x889FE3FF),
                const Color(0x44408CA8),
              ],
            ).createShader(ground),
        );
        p.shader = null;
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (final r in [(0.34, 0.56, 12.0), (0.69, 0.52, 9.5)]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(size.width * r.$1, size.height * r.$2),
              width: r.$3 * 2,
              height: r.$3 * .6,
            ),
            p..color = crestColor.withValues(alpha: .55),
          );
        }
        p.style = PaintingStyle.fill;
      case 2: // Forest: soft moss patches & grassy blade tufts
        for (final m in [(0.30, 0.50, 18.0), (0.68, 0.48, 20.0)]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(size.width * m.$1, size.height * m.$2),
              width: m.$3 * 2,
              height: m.$3 * .45,
            ),
            p..color = detailColor.withValues(alpha: .35),
          );
        }
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        for (final bx in [0.19, 0.23, 0.28, 0.72, 0.76, 0.81]) {
          final x = size.width * bx;
          final y = size.height * .58;
          canvas.drawLine(
            Offset(x, y),
            Offset(x + (bx < .5 ? -3.5 : 3.5), y - 6.5),
            p..color = crestColor.withValues(alpha: .72),
          );
        }
        p.style = PaintingStyle.fill;
      case 3: // Glacial Tundra: crisp ice facets & frost highlights
        for (final f in [
          (0.24, 0.44, 0.42, 0.56),
          (0.56, 0.40, 0.76, 0.54),
        ]) {
          canvas.drawPath(
            Path()
              ..moveTo(size.width * f.$1, size.height * f.$2)
              ..lineTo(size.width * f.$3, size.height * f.$2)
              ..lineTo(size.width * (f.$3 - .06), size.height * f.$4)
              ..close(),
            p..color = Colors.white.withValues(alpha: .42),
          );
        }
        for (final pt in [(0.27, 0.56), (0.72, 0.54), (0.62, 0.65)]) {
          canvas.drawCircle(
            Offset(size.width * pt.$1, size.height * pt.$2),
            2.1,
            p..color = Colors.white.withValues(alpha: .82),
          );
        }
      case 4: // Volcano Inferno: glowing molten lava fissures in dark basalt
        p
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final fissures = [
          Path()
            ..moveTo(size.width * .18, size.height * .54)
            ..lineTo(size.width * .32, size.height * .58)
            ..lineTo(size.width * .40, size.height * .66),
          Path()
            ..moveTo(size.width * .62, size.height * .64)
            ..lineTo(size.width * .72, size.height * .56)
            ..lineTo(size.width * .84, size.height * .54),
        ];
        for (final crack in fissures) {
          canvas.drawPath(
            crack,
            p
              ..strokeWidth = 4.2
              ..color = detailColor.withValues(alpha: .48),
          );
          canvas.drawPath(
            crack,
            p
              ..strokeWidth = 1.7
              ..color = const Color(0xFFFFE07A).withValues(alpha: .92),
          );
        }
        p.style = PaintingStyle.fill;
      case 5: // Cosmic Orbit: lunar craters & glowing star crystals
        for (final c in [
          (0.26, 0.54, 12.0, 4.8),
          (0.73, 0.52, 14.0, 5.2),
          (0.60, 0.64, 8.0, 3.2),
        ]) {
          final rect = Rect.fromCenter(
            center: Offset(size.width * c.$1, size.height * c.$2),
            width: c.$3 * 2,
            height: c.$4 * 2,
          );
          canvas.drawOval(rect, p..color = const Color(0x55100E2E));
          canvas.drawArc(
            rect,
            .2,
            2.7,
            false,
            p
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = detailColor.withValues(alpha: .52),
          );
          p.style = PaintingStyle.fill;
        }
        for (final pt in [(0.36, 0.44), (0.78, 0.47), (0.21, 0.62)]) {
          canvas.drawCircle(
            Offset(size.width * pt.$1, size.height * pt.$2),
            1.9,
            p..color = detailColor.withValues(alpha: .85),
          );
        }
    }
    canvas.restore();

    // Subtle sunlit ridge line along the top crest.
    final crest = Path()
      ..moveTo(size.width * .14, size.height * .53)
      ..quadraticBezierTo(size.width * .28, size.height * .27, size.width * .50, size.height * .27)
      ..quadraticBezierTo(size.width * .72, size.height * .27, size.width * .86, size.height * .53);
    canvas.drawPath(
      crest,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..color = crestColor.withValues(alpha: 0.60),
    );
    // Contact shadow anchored directly beneath Dino's soles (aligned at ledge middle).
    p.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .50, size.height * .52),
        width: size.width * .58,
        height: size.height * .24,
      ),
      p
        ..shader = const RadialGradient(
          colors: [Color(0xB80E141D), Color(0x000E141D)],
        ).createShader(ground),
    );
  }

  @override
  bool shouldRepaint(_DinoTrailLedgePainter old) => old.stage != stage;
}
