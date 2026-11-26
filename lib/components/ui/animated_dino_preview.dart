import 'dart:math' as math;
import '../../utils/cart_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../skins/skin.dart';
import '../../skins/skin_registry.dart';
import '../../skins/new_dino_skin.dart';

/// Each mounted preview owns its rig and elapsed clock; painting is read-only.
class AnimatedDinoPreview extends StatefulWidget {
  final CharacterSkin template;
  final bool interactive;
  final int equipReaction;
  final String? cartSkinId;
  const AnimatedDinoPreview({
    super.key,
    required this.template,
    this.interactive = false,
    this.cartSkinId,
    this.equipReaction = 0,
  });
  @override
  State<AnimatedDinoPreview> createState() => _AnimatedDinoPreviewState();
}

class _AnimatedDinoPreviewState extends State<AnimatedDinoPreview>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final CharacterSkin skin = SkinRegistry.createInstance(
    widget.template.id,
  );
  final repaint = ValueNotifier<int>(0);
  late final Ticker ticker;
  Duration previous = Duration.zero;
  bool _quiet = false, _foreground = true;
  int _hello = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    skin.cosmetics = widget.template.cosmetics;
    ticker = createTicker((elapsed) {
      final dt = (elapsed - previous).inMicroseconds / 1e6;
      previous = elapsed;
      skin.cosmetics = widget.template.cosmetics;
      if (skin is NewDinoSkin) {
        (skin as NewDinoSkin).motion.driving = widget.cartSkinId != null;
      }
      skin.advanceMotion(
        dt.clamp(0, .1),
        speed: 200,
        velocityY: 0,
        grounded: true,
        idle: widget.cartSkinId == null,
      );
      repaint.value++;
    });
  }

  void _syncTicker() {
    final running = !_quiet && _foreground && TickerMode.valuesOf(context).enabled;
    if (running && !ticker.isActive) {
      previous = Duration.zero;
      ticker.start();
    } else if (!running && ticker.isActive) {
      ticker.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _quiet = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant AnimatedDinoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    skin.cosmetics = widget.template.cosmetics;
    if (oldWidget.equipReaction != widget.equipReaction &&
        !_quiet && skin is NewDinoSkin) {
      (skin as NewDinoSkin).motion.idleTime = 12.4;
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.interactive
        ? () {
            if (!_quiet && skin is NewDinoSkin) {
              (skin as NewDinoSkin).motion.idleTime = 12.9;
            }
            setState(() => _hello++);
          }
        : null,
    child: Semantics(
      label: widget.interactive ? 'Say hello to Dino' : 'Dino preview',
      button: widget.interactive,
      child: RepaintBoundary(
        child: ClipRect(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              CustomPaint(
                size: const Size(80, 96),
                painter: _PreviewPainter(skin, repaint, widget.cartSkinId),
              ),
              if (_quiet && _hello > 0)
                const Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text('Hello!', style: TextStyle(
                      color: Color(0xFF24334E), backgroundColor: Color(0xFFFFF1CA),
                      fontFamily: 'Fredoka', fontSize: 18,
                    )),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewPainter extends CustomPainter {
  final CharacterSkin skin;
  final String? cartSkinId;
  _PreviewPainter(this.skin, Listenable repaint, this.cartSkinId)
    : super(repaint: repaint);
  @override
  void paint(Canvas canvas, Size size) {
    if (cartSkinId == null) {
      skin.renderCharacter(canvas, size, 0);
      return;
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = math.min(size.width / 108, size.height / 108);
    canvas.translate((size.width - 103 * scale) / 2, size.height - 106 * scale);
    canvas.scale(scale);
    canvas.save();
    canvas.translate(0, 55);
    CartArt.rear(canvas, skinId: cartSkinId!);
    canvas.restore();
    canvas.save();
    // Seated feet remain inside the chassis, including its transparent wheel gap.
    canvas.clipRect(const Rect.fromLTWH(-10, -20, 130, 111));
    canvas.translate(5, 9);
    skin.renderCharacter(canvas, const Size(80, 96), 0);
    canvas.restore();
    canvas.translate(0, 55);
    CartArt.front(
      canvas,
      charges: 3,
      distance: skin is NewDinoSkin
          ? (skin as NewDinoSkin).motion.time * 35
          : 0,
      skinId: cartSkinId!,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.skin != skin || old.cartSkinId != cartSkinId;
}
