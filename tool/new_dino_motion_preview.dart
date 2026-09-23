import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NewDinoSkin.preload();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MotionPreview()));
}
class MotionPreview extends StatefulWidget {
  const MotionPreview({super.key});
  @override
  State<MotionPreview> createState() => _MotionPreviewState();
}
class _MotionPreviewState extends State<MotionPreview> with SingleTickerProviderStateMixin {
  final dino = NewDinoSkin();
  late final Ticker ticker;
  Duration previous = Duration.zero;
  double speed = 300, rate = 1, y = 0, velocity = 0;
  bool idle = false, paused = false, outfit = true;
  @override
  void initState() {
    super.initState();
    dino.cosmetics = [CosmeticCatalog.items[0], CosmeticCatalog.items[2]];
    ticker = createTicker((elapsed) {
      final dt = ((elapsed - previous).inMicroseconds / 1e6).clamp(0.0, .05) * rate;
      previous = elapsed;
      if (paused) return;
      if (y < 0 || velocity < 0) {
        velocity += 1500 * dt;
        y += velocity * dt;
        if (y >= 0) { y = 0; velocity = 0; }
      }
      dino.advanceMotion(dt, speed: speed, velocityY: velocity,
        grounded: y == 0 && velocity >= 0, idle: idle);
      setState(() {});
    })..start();
  }
  @override
  void dispose() { ticker.dispose(); super.dispose(); }
  void jump() { setState(() { idle = false; velocity = -550; dino.onJump(); }); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF122334),
    body: SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.all(14), child: Text('New Dino — motion review',
        style: TextStyle(color: Colors.white, fontSize: 24))),
      Wrap(spacing: 10, children: [
        ElevatedButton(onPressed: () => setState(() => idle = !idle), child: Text(idle ? 'Run' : 'Idle')),
        ElevatedButton(onPressed: jump, child: const Text('Jump / double jump')),
        ElevatedButton(onPressed: () => setState(() => paused = !paused), child: Text(paused ? 'Resume' : 'Pause')),
        ElevatedButton(onPressed: () => setState(() => rate = rate == 1 ? .25 : 1), child: Text(rate == 1 ? 'Slow motion' : 'Normal speed')),
        ElevatedButton(onPressed: () => setState(() { outfit = !outfit; dino.cosmetics = outfit ? [CosmeticCatalog.items[0], CosmeticCatalog.items[2]] : []; }), child: const Text('Cosmetics')),
      ]),
      Slider(value: speed, min: 150, max: 650, label: '${speed.round()} px/s', onChanged: (v) => setState(() => speed = v)),
      Expanded(child: CustomPaint(painter: _ReviewPainter(dino, y, speed), child: const SizedBox.expand())),
    ])),
  );
}
class _ReviewPainter extends CustomPainter {
  final NewDinoSkin dino;
  final double y, speed;
  _ReviewPainter(this.dino, this.y, this.speed);
  @override
  void paint(Canvas c, Size s) {
    final floor = s.height - 20;
    c.drawLine(Offset(0, floor), Offset(s.width, floor), Paint()..color = const Color(0xFF95BBA4)..strokeWidth = 2);
    for (double x = -(dino.motion.time * speed * 3 % 100); x < s.width; x += 100) {
      c.drawLine(Offset(x, floor + 5), Offset(x + 18, floor + 5), Paint()..color = Colors.white24..strokeWidth = 2);
    }
    c.save();
    c.translate(s.width / 2 - 120, floor - 288 + y * .4);
    dino.renderCharacter(c, const Size(240, 288), 0);
    c.restore();
  }
  @override
  bool shouldRepaint(_ReviewPainter old) => true;
}
