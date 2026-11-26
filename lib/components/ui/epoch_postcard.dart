import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';

class EpochPostcard extends StatelessWidget {
  static const descriptions = [
    'Fossil canyons & sunlit trails',
    'Rainy paths & fallen timber',
    'Ancient trees & winding roots',
    'Frozen cliffs & icy crossings',
    'Lava fissures & fiery rocks',
    'A trail beneath distant planets',
  ];
  final int stage, selected;
  final List<String> names;
  final IconData? icon;
  final ValueChanged<int> onSelect;
  const EpochPostcard({
    super.key,
    required this.stage,
    required this.selected,
    required this.names,
    required this.onSelect,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final targetHeight = bounds.maxWidth >= 380 ? 156.0 : 140.0;
      final height = bounds.hasBoundedHeight
          ? math.min(targetHeight, bounds.maxHeight)
          : targetHeight;
      final accent = MenuPalette.accents[stage % MenuPalette.accents.length];
      ButtonStyle arrowStyle(bool enabled) => IconButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xEB1B2B40)
            : const Color(0x6E121D2C),
        hoverColor: const Color(0xF5253A54),
        side: BorderSide(
          color: enabled ? const Color(0xFFE0B462) : const Color(0x45D7AB5E),
          width: 1.7,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: const Color(0xFFFFF7E2),
        disabledForegroundColor: const Color(0x94FFF0CA),
        minimumSize: const Size(48, 48),
        fixedSize: const Size(48, 48),
      );
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          foregroundPainter: _PostcardFramePainter(accent),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3E2D1A), width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF2E2012),
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x700E1724),
                  offset: Offset(0, 9),
                  blurRadius: 18,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EpochBiomeImage(stage: stage),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x58172638),
                          Color(0xC8101C2B),
                          Color(0xEB0B1522),
                        ],
                        stops: [0, .52, 1],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: IconButton(
                          tooltip: 'Previous epoch',
                          style: arrowStyle(selected > 0),
                          onPressed: selected > 0
                              ? () => onSelect(selected - 1)
                              : null,
                          icon: const MenuChevron(left: true, size: 26),
                        ),
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, inner) => Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: inner.maxWidth,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          MediaQuery.disableAnimationsOf(context)
                                              ? Duration.zero
                                              : const Duration(milliseconds: 220),
                                      child: Row(
                                        key: ValueKey(selected),
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          EpochEmblem(stage: stage, size: 22),
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: Text(
                                              names[selected],
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Fredoka',
                                                fontSize: 19,
                                                fontWeight: FontWeight.w800,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      descriptions[stage % 6],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFFFF0CE),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x8E101B29),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0x4DDAB164),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            for (
                                              var i = 0;
                                              i < names.length;
                                              i++
                                            )
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                    ),
                                                child: AnimatedContainer(
                                                  duration:
                                                      MediaQuery.disableAnimationsOf(
                                                            context,
                                                          )
                                                          ? Duration.zero
                                                          : const Duration(
                                                              milliseconds: 180,
                                                            ),
                                                  width: i == selected ? 20 : 8,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    color: i == selected
                                                        ? MenuPalette.gold
                                                        : const Color(0x72FFFFFF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3.5,
                                                        ),
                                                    border: Border.all(
                                                      color: i == selected
                                                          ? const Color(
                                                              0xFFFFF1C1,
                                                            )
                                                          : const Color(
                                                              0x30FFFFFF,
                                                            ),
                                                      width: 0.9,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${selected + 1} / ${names.length}',
                                              style: const TextStyle(
                                                color: Color(0xFFFFF5DC),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
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
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        tooltip: 'Next epoch',
                        style: arrowStyle(selected < names.length - 1),
                        onPressed: selected < names.length - 1
                            ? () => onSelect(selected + 1)
                            : null,
                        icon: const MenuChevron(left: false, size: 26),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      );
    },
  );
}

class _PostcardFramePainter extends CustomPainter {
  final Color accent;
  const _PostcardFramePainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 48 || size.height < 48) return;
    final outer = Offset.zero & size;
    final stroke = Paint()..style = PaintingStyle.stroke;
    // Beveled bronze/timber inner rim around the epoch vista.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(2.4), const Radius.circular(15.6)),
      stroke
        ..color = Color.lerp(const Color(0xFFD6AC64), accent, .30)!
        ..strokeWidth = 2.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(4.0), const Radius.circular(14.0)),
      stroke
        ..color = const Color(0x55FFF5D6)
        ..strokeWidth = 1.0,
    );
    // Brass rivets anchored at all four frame corners.
    final dot = Paint()..style = PaintingStyle.fill;
    for (final pt in [
      const Offset(9.0, 9.0),
      Offset(size.width - 9.0, 9.0),
      Offset(9.0, size.height - 9.0),
      Offset(size.width - 9.0, size.height - 9.0),
    ]) {
      canvas.drawCircle(pt, 2.2, dot..color = const Color(0xFF3E2C18));
      canvas.drawCircle(
        pt.translate(-0.3, -0.35),
        1.4,
        dot..color = const Color(0xFFFFD877),
      );
    }
  }

  @override
  bool shouldRepaint(_PostcardFramePainter old) => old.accent != accent;
}

/// A few drifting pollen, snow or starlight motes; one isolated repaint layer.
class CampAtmosphere extends StatefulWidget {
  final int stage;
  const CampAtmosphere({super.key, required this.stage});
  @override
  State<CampAtmosphere> createState() => _CampAtmosphereState();
}

class _CampAtmosphereState extends State<CampAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.valuesOf(context).enabled) {
      clock.stop();
    } else if (!clock.isAnimating) {
      clock.repeat();
    }
  }
  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _Motes(clock, widget.stage)),
    ),
  );
}

class _Motes extends CustomPainter {
  final Animation<double> clock;
  final int stage;
  _Motes(this.clock, this.stage) : super(repaint: clock);
  @override
  void paint(Canvas c, Size size) {
    for (var i = 0; i < 9; i++) {
      final phase = (clock.value + i * .113) % 1;
      final x = (i * .173 + clock.value * .06) % 1 * size.width;
      final y = (.15 + phase * .64) * size.height;
      final opacity = math.sin(phase * math.pi) * .42;
      c.drawCircle(
        Offset(x + math.sin(phase * math.pi * 2 + i) * 9, y),
        stage == 3 ? 2 : 1.5,
        Paint()
          ..color = (stage == 3 || stage == 5 ? Colors.white : MenuPalette.gold)
              .withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_Motes old) => old.stage != stage;
}
