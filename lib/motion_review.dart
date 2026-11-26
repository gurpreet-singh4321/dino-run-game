import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'skins/new_dino_skin.dart';
import 'skins/cosmetics.dart';

/// Separate, deterministic playback entry point; never loads or changes a save.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NewDinoSkin.preload();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MotionReviewPage(),
    ),
  );
}

enum ReviewPose {
  idle,
  yawn,
  look,
  wave,
  run,
  jump,
  doubleJump,
  fall,
  land,
  damage,
  rocket,
}

class MotionReviewPage extends StatefulWidget {
  const MotionReviewPage({super.key});
  @override
  State<MotionReviewPage> createState() => _MotionReviewPageState();
}

class _MotionReviewPageState extends State<MotionReviewPage>
    with SingleTickerProviderStateMixin {
  final skin = NewDinoSkin();
  late final Ticker ticker;
  Duration previous = Duration.zero;
  ReviewPose pose = ReviewPose.run;
  double rate = 1;
  double age = 0;
  bool playing = true;
  bool outfit = true;
  @override
  void initState() {
    super.initState();
    skin.cosmetics = CosmeticCatalog.items
        .where((item) => item.id != 'winter_hat')
        .toList();
    ticker = createTicker((elapsed) {
      final dt = (elapsed - previous).inMicroseconds / 1e6;
      previous = elapsed;
      if (playing) {
        setState(() => advance(dt.clamp(0, .05) * rate));
      }
    })..start();
  }

  void select(ReviewPose next) {
    pose = next;
    age = 0;
    skin.resetMotion();
    if ([ReviewPose.yawn, ReviewPose.look, ReviewPose.wave].contains(next)) {
      final seedTime = next == ReviewPose.yawn
          ? 4.3
          : next == ReviewPose.look
          ? 9.2
          : 13.1;
      for (var i = 0; i < (seedTime * 120).round(); i++) {
        skin.advanceMotion(
          1 / 120,
          speed: 0,
          velocityY: 0,
          grounded: true,
          idle: true,
        );
      }
    }
    if (next == ReviewPose.jump || next == ReviewPose.doubleJump) {
      skin.onJump(doubleJump: next == ReviewPose.doubleJump);
    }
    if (next == ReviewPose.damage) skin.onDamage();
    if (next == ReviewPose.land) {
      skin.advanceMotion(.1, speed: 200, velocityY: 500, grounded: false);
    }
  }

  void advance(double dt) {
    age += dt;
    if (age > 1.5 &&
        [
          ReviewPose.land,
          ReviewPose.damage,
          ReviewPose.doubleJump,
          ReviewPose.yawn,
          ReviewPose.look,
          ReviewPose.wave,
        ].contains(pose)) {
      select(pose);
    }
    final airborne = [
      ReviewPose.jump,
      ReviewPose.doubleJump,
      ReviewPose.fall,
      ReviewPose.rocket,
    ].contains(pose);
    skin.advanceMotion(
      dt,
      speed: 200,
      velocityY: pose == ReviewPose.fall
          ? 450
          : airborne
          ? -300
          : 0,
      grounded: !airborne,
      idle: [
        ReviewPose.idle,
        ReviewPose.yawn,
        ReviewPose.look,
        ReviewPose.wave,
      ].contains(pose),
      space: pose == ReviewPose.rocket,
    );
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF3DD),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Dino motion review',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<ReviewPose>(
                  value: pose,
                  items: ReviewPose.values
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (p) => setState(() => select(p!)),
                ),
                TextButton(
                  onPressed: () => setState(() => rate = rate == 1 ? .25 : 1),
                  child: Text(rate == 1 ? '1× speed' : '0.25× speed'),
                ),
                TextButton(
                  onPressed: () => setState(() => playing = !playing),
                  child: Text(playing ? 'Pause' : 'Play'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    playing = false;
                    advance(1 / 120);
                  }),
                  child: const Text('Step'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    outfit = !outfit;
                    skin.cosmetics = outfit
                        ? CosmeticCatalog.items
                              .where((item) => item.id != 'winter_hat')
                              .toList()
                        : [];
                  }),
                  child: Text(outfit ? 'Outfit on' : 'Outfit off'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 2.5,
                child: CustomPaint(painter: _MotionStage(skin)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'State: ${skin.motion.state.name} · frame step 1/120 s · floor line and joint anchors shown',
            ),
          ),
        ],
      ),
    ),
  );
}

class _MotionStage extends CustomPainter {
  final NewDinoSkin skin;
  _MotionStage(this.skin);
  @override
  void paint(Canvas c, Size size) {
    final s = size.height / 150;
    c.save();
    c.translate(size.width / 2 - 50 * s, 10 * s);
    c.scale(s);
    c.drawLine(
      const Offset(-150, 120),
      const Offset(250, 120),
      Paint()
        ..color = const Color(0xFF97734D)
        ..strokeWidth = .5,
    );
    c.drawOval(
      const Rect.fromLTWH(33, 117, 48, 6),
      Paint()..color = const Color(0x443D281B),
    );
    skin.renderCharacter(c, const Size(100, 120), 0);
    final jointPaint = Paint()..color = const Color(0xAA177D91);
    for (final far in [false, true]) {
      final foot = skin.motion.foot(far);
      c.drawCircle(foot + const Offset(0, 7), 1, jointPaint);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _MotionStage oldDelegate) => true;
}
