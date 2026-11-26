import 'package:flutter/material.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import '../../managers/audio_manager.dart';
import '../../utils/coin_art.dart';
import 'adventure_panels.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';

/// Actual run totals and existing actions, reachable by touch or keyboard.
class RunResults extends StatefulWidget {
  final DinoGame game;
  const RunResults({super.key, required this.game});
  @override
  State<RunResults> createState() => _RunResultsState();
}

class _RunResultsState extends State<RunResults> {
  bool _acted = false;
  void act(VoidCallback callback) {
    if (_acted || widget.game.state != GameState.gameOver) return;
    _acted = true;
    AudioManager.playButton();
    callback();
  }
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final scoreVal = game.score.toInt();
    final isBest = scoreVal > 0 && scoreVal >= game.coinManager.highScore;
    final coinGoal = game.coinManager.collectedCoins.clamp(0, 50);
    final missionDone = game.coinManager.isMissionClaimed(0);
    return AdventurePanel(
      title: 'What an adventure!',
      subtitle: 'Ready for another trail?',
      symbol: MenuSymbol.journal,
      accent: MenuPalette.forest,
      coins: game.coinManager.coins,
      maxWidth: 530,
      maxHeight: 422,
      stage: game.biomeManager.currentStage,
      onClose: () => act(game.exitToMenu),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF283B55), Color(0xFF172437)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCFA55C), width: 1.7),
                      boxShadow: const [BoxShadow(color: Color(0x380E1622), offset: Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EpochEmblem(stage: game.biomeManager.currentStage, size: 26),
                            const SizedBox(width: 10),
                            Text(
                              '$scoreVal',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 38,
                                height: 1.0,
                                fontWeight: FontWeight.w800,
                                color: MenuPalette.gold,
                                shadows: [Shadow(color: Color(0xAA0C121B), offset: Offset(0, 2), blurRadius: 4)],
                              ),
                            ),
                            if (isBest) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: MenuPalette.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'BEST',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: MenuPalette.ink,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Run score · Best ${game.coinManager.highScore}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE7EFFA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RunStatCard(
                          icon: const SizedBox.square(
                            dimension: 24,
                            child: CustomPaint(painter: _ResultCoinArt()),
                          ),
                          text: '+${game.coinManager.runCoins} run coins',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RunStatCard(
                          icon: const SizedBox.square(
                            dimension: 24,
                            child: CustomPaint(painter: _SmashArt()),
                          ),
                          text: '${game.smashedObjects} objects smashed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE0C2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBB082), width: 1.3),
                    ),
                    child: Row(
                      children: [
                        const MenuIllustration(MenuSymbol.journal, size: 19),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            missionDone
                                ? 'Coin discovery recorded in your Journal'
                                : 'Journal: $coinGoal / 50 coins collected',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: MenuPalette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: Color(0x302A1B08), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: CustomPaint(
                        painter: const PlaqueBadgePainter(
                          top: Color(0xFFFFF0B8),
                          mid: Color(0xFFFFCA52),
                          bottom: Color(0xFFE09B22),
                          outline: Color(0xFF56340B),
                          lip: Color(0xFF804E10),
                          innerRim: Color(0xD8FFF8DB),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 52),
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 9),
                            foregroundColor: MenuPalette.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => act(game.reviveGame),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: MenuPalette.slate,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: const Color(0xFFD6A856), width: 1.4),
                                ),
                                child: const CustomPaint(painter: _AdVideoArt()),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Revive · continue this run',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: MenuPalette.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: MenuPalette.slate,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: const Color(0xFFD6A856), width: 1.2),
                                ),
                                child: const Text(
                                  'AD',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: MenuPalette.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: MenuAction(
                    symbol: MenuSymbol.home,
                    label: 'Main menu',
                    color: MenuPalette.slate,
                    onPressed: () => act(game.exitToMenu),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: MenuAction(
                    symbol: MenuSymbol.play,
                    label: 'Retry',
                    color: const Color(0xFF136C51),
                    prominent: true,
                    showSymbol: false,
                    onPressed: () => act(() => game.startGame()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunStatCard extends StatelessWidget {
  final Widget icon;
  final String text;
  const _RunStatCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFCF6), Color(0xFFF6EAD1)],
      ),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFCEB589), width: 1.4),
      boxShadow: const [BoxShadow(color: Color(0x26543E22), offset: Offset(0, 2))],
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFEFDFC0),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFCBB082), width: 1.2),
          ),
          child: icon,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: MenuPalette.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ResultCoinArt extends CustomPainter {
  const _ResultCoinArt();
  @override
  void paint(Canvas canvas, Size size) =>
      CoinArt.draw(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_ResultCoinArt old) => false;
}

class _SmashArt extends CustomPainter {
  const _SmashArt();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final ink = Paint()
      ..color = const Color(0xFF1F2A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    final star = Path()
      ..moveTo(12, 2)
      ..lineTo(14.8, 7.6)
      ..lineTo(21, 6.2)
      ..lineTo(17.5, 11.4)
      ..lineTo(22, 16.2)
      ..lineTo(15.6, 16.5)
      ..lineTo(13.5, 22)
      ..lineTo(10.2, 16.8)
      ..lineTo(4, 18.2)
      ..lineTo(7, 12.6)
      ..lineTo(2.5, 8)
      ..lineTo(8.8, 7.8)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFE07D35));
    canvas.drawPath(star, ink);
    canvas.drawCircle(const Offset(12, 12), 3.4, Paint()..color = const Color(0xFFFFD86A));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SmashArt old) => false;
}

class _AdVideoArt extends CustomPainter {
  const _AdVideoArt();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 20, size.height / 20);
    // Clapper/video screen frame + golden play triangle signaling rewarded ad.
    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1.5, 3.5, 17, 13),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..color = const Color(0xFFFFD670)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    final play = Path()
      ..moveTo(7.8, 6.6)
      ..lineTo(14.0, 10.0)
      ..lineTo(7.8, 13.4)
      ..close();
    canvas.drawPath(play, Paint()..color = const Color(0xFFFFD670));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AdVideoArt old) => false;
}
