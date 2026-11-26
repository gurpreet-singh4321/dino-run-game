import 'package:flutter/material.dart';
import '../../utils/coin_art.dart';
import '../../utils/scenery_cache.dart';
import 'menu_motion.dart';

class MenuPalette {
  static const ink = Color(0xFF1F2D42), muted = Color(0xFF5D6B80);
  static const paper = Color(0xFFFDF8EC), edge = Color(0xFFDFCFAF);
  static const forest = Color(0xFF128075), gold = Color(0xFFFFCB55);
  static const coral = Color(0xFFC25831), violet = Color(0xFF5A52B8);
  static const blue = Color(0xFF2360AE);
  static const orange = Color(0xFFC0621E), red = Color(0xFFC83F44);
  static const slate = Color(0xFF1E2E44), emerald = Color(0xFF1A9264);
  static const terracotta = Color(0xFFC25831), teal = Color(0xFF128075);
  static const amber = Color(0xFFE08C28);
  static const accents = [gold, blue, emerald, teal, terracotta, violet];
}

class EpochScenery extends StatefulWidget {
  final int stage;
  final bool dim;
  const EpochScenery({super.key, this.stage = 0, this.dim = false});
  static const artwork = [
    'desert_fossil_canyon.png',
    'rain_painted_v1.png',
    'forest_painted_v1.png',
    'ice_painted_v1.png',
    'volcano_painted_v1.png',
    'cosmos_painted_v1.png',
  ];
  static ImageProvider imageFor(int stage) => AssetImage(
    'assets/images/biomes/${artwork[stage % artwork.length]}',
  );
  @override
  State<EpochScenery> createState() => _EpochSceneryState();
}

/// Renders an epoch backdrop `Image`, falling back instantaneously to `SceneryCache`
/// while `AssetImage` decodes its first frame on Web/CanvasKit.
class EpochBiomeImage extends StatelessWidget {
  final int stage;
  const EpochBiomeImage({super.key, required this.stage});
  @override
  Widget build(BuildContext context) {
    final name = EpochScenery.artwork[stage % EpochScenery.artwork.length];
    return Image(
      image: EpochScenery.imageFor(stage),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) {
        final cached = SceneryCache.getCached(name);
        return cached != null
            ? RawImage(
                image: cached,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.low,
              )
            : const SizedBox.shrink();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) return child;
        final cached = SceneryCache.getCached(name);
        if (cached != null) {
          return RawImage(
            image: cached,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.low,
          );
        }
        return child;
      },
    );
  }
}

class _EpochSceneryState extends State<EpochScenery>
    with SingleTickerProviderStateMixin {
  late int _current = widget.stage;
  int? _incoming, _pending;
  int _request = 0;
  late final AnimationController _fade;
  @override
  void initState() {
    super.initState();
    _fade =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed) return;
          setState(() {
            _current = _incoming!;
            _incoming = null;
          });
          _beginPending();
        });
  }

  @override
  void didUpdateWidget(EpochScenery old) {
    super.didUpdateWidget(old);
    if (old.stage != widget.stage) _prepare(widget.stage);
  }

  Future<void> _prepare(int stage) async {
    final request = ++_request;
    _pending = null;
    // Never fade to an undecoded image or expose the game beneath the menu.
    await precacheImage(EpochScenery.imageFor(stage), context);
    if (!mounted || request != _request) return;
    _pending = stage;
    _beginPending();
  }

  void _beginPending() {
    if (_incoming != null || _pending == null) return;
    final stage = _pending!;
    _pending = null;
    if (stage == _current) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _current = stage);
      return;
    }
    setState(() => _incoming = stage);
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Widget _scene(int stage, String layer) => EpochBiomeImage(
    key: ValueKey('epoch-$layer-$stage'),
    stage: stage,
  );

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF6C765E)),
          _scene(_current, 'current'),
          if (_incoming != null)
            FadeTransition(
              opacity: _fade.drive(CurveTween(curve: Curves.easeInOut)),
              child: _scene(_incoming!, 'incoming'),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.dim
                    ? [const Color(0x9933231E), const Color(0xAA1E2E29)]
                    : [
                        const Color(0x7032271E),
                        Colors.transparent,
                        const Color(0xAA30261C),
                      ],
                stops: widget.dim ? null : const [0, .45, 1],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MenuPaper extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color accent;
  const MenuPaper({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.accent = MenuPalette.forest,
  });
  @override
  Widget build(BuildContext context) => MenuArrival(
    child: CustomPaint(
      foregroundPainter: _BoardFramePainter(accent),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF3), Color(0xFFF3E7CD)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF5D462B),
            width: 2.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55101824),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0xAA43311D),
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class _BoardFramePainter extends CustomPainter {
  final Color accent;
  const _BoardFramePainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 40 || size.height < 40) return;
    final outer = Offset.zero & size;
    final p = Paint()..style = PaintingStyle.stroke;
    // Inner warm bronze trim inside the timber outer contour.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(2.5), const Radius.circular(19.5)),
      p
        ..color = Color.lerp(const Color(0xFFD5B070), accent, .18)!
        ..strokeWidth = 2.0,
    );
    // Crisp sunlit inner bevel along the parchment rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(4.4), const Radius.circular(17.5)),
      p
        ..color = const Color(0x99FFFBF0)
        ..strokeWidth = 1.0,
    );
    // Corner brass studs anchored into the rounded frame corners.
    p.style = PaintingStyle.fill;
    for (final pt in [
      const Offset(9.5, 9.5),
      Offset(size.width - 9.5, 9.5),
      Offset(9.5, size.height - 9.5),
      Offset(size.width - 9.5, size.height - 9.5),
    ]) {
      canvas.drawCircle(pt, 2.3, p..color = const Color(0xFF47331D));
      canvas.drawCircle(
        pt.translate(-0.3, -0.35),
        1.45,
        p..color = const Color(0xFFFFD97D),
      );
    }
  }

  @override
  bool shouldRepaint(_BoardFramePainter old) => old.accent != accent;
}

class MenuCoinBalance extends StatelessWidget {
  final int coins;
  const MenuCoinBalance({super.key, required this.coins});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$coins coins',
    excludeSemantics: true,
    child: SizedBox(
      height: 48,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: CustomPaint(
          painter: const PlaqueBadgePainter(
            top: Color(0xFFFFF2C2),
            mid: MenuPalette.gold,
            bottom: Color(0xFFE09F24),
            outline: Color(0xFF4F320D),
            lip: Color(0xFF7B4E14),
            innerRim: Color(0xBAFFF9E0),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CustomPaint(painter: _CoinArt()),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$coins',
                      style: const TextStyle(
                        color: MenuPalette.ink,
                        fontFamily: 'Fredoka',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shared 3D carved plaque chrome matching interactive button bevels and lips.
class PlaqueBadgePainter extends CustomPainter {
  final Color top, mid, bottom, outline, lip, innerRim;
  const PlaqueBadgePainter({
    required this.top,
    required this.mid,
    required this.bottom,
    required this.outline,
    required this.lip,
    required this.innerRim,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final face = Rect.fromLTWH(1.2, 1.2, size.width - 2.4, size.height - 7.4);
    const radius = Radius.circular(14);
    const innerRadius = Radius.circular(11.5);
    final p = Paint();
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), p..color = outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.0), radius),
      p..color = lip,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, radius),
      p
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
          stops: const [0, .48, 1],
        ).createShader(face),
    );
    p.shader = null;
    canvas.drawRRect(
      RRect.fromRectAndRadius(face.deflate(2.3), innerRadius),
      p
        ..color = innerRim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    p.style = PaintingStyle.fill;
    if (face.width > 24) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(face.left + 9, face.top + 3.2, face.width - 18, 2.0),
          const Radius.circular(1.5),
        ),
        p..color = const Color(0x45FFFDF2),
      );
    }
  }

  @override
  bool shouldRepaint(PlaqueBadgePainter old) =>
      top != old.top || mid != old.mid || bottom != old.bottom;
}

class _CoinArt extends CustomPainter {
  const _CoinArt();
  @override
  void paint(Canvas canvas, Size size) =>
      CoinArt.draw(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_CoinArt old) => false;
}
