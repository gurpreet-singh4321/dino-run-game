import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import 'menu_chrome.dart';

/// Compact explorer results, using the same coordinates as the input handler.
class GameOverScreen extends PositionComponent with HasGameReference<DinoGame> {
  double _arrival = 0;
  @override
  void update(double dt) {
    super.update(dt);
    _arrival = game.state == GameState.gameOver
        ? (_arrival + dt).clamp(0, 1)
        : 0;
  }

  @override
  Future<void> onLoad() async {
    priority = 100;
  }

  @override
  void render(Canvas canvas) {
    if (game.state != GameState.gameOver || game.useFlutterResults) return;
    final cx = game.size.x / 2, cy = game.size.y / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = const Color(0xB325384A),
    );
    final panel = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 380,
      height: 248,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel.translate(0, 4), const Radius.circular(24)),
      Paint()..color = const Color(0x5525384A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(24)),
      Paint()..color = const Color(0xFFFFF7E5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(24)),
      Paint()
        ..color = MenuPalette.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    void text(
      String value,
      double y, {
      double size = 16,
      Color color = MenuPalette.ink,
      FontWeight weight = FontWeight.w700,
    }) {
      TextPaint(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          color: color,
          fontWeight: weight,
        ),
      ).render(canvas, value, Vector2(cx, y), anchor: Anchor.topCenter);
    }

    text('What an adventure!', cy - 99, size: 25, color: MenuPalette.forest);
    text(
      'Score ${game.score.toInt()}  ·  Best ${game.coinManager.highScore}',
      cy - 60,
      size: 18,
    );
    text(
      '+${game.coinManager.runCoins} run coins  ·  ${game.smashedObjects} objects smashed',
      cy - 27,
      size: 15,
    );
    final goal = game.coinManager.isMissionClaimed(0)
        ? 'Coin discovery recorded in your Journal'
        : 'Journal: ${game.coinManager.collectedCoins.clamp(0, 50)} / 50 coins collected';
    text(goal, cy + 4, size: 13, color: MenuPalette.muted);
    for (var i = 0; i < 3; i++) {
      final x = cx + (i - 1) * 116;
      final rect = Rect.fromCenter(
        center: Offset(x, cy + 70),
        width: 108,
        height: 54,
      );
      final context = game.buildContext;
      final quiet = context != null && MediaQuery.disableAnimationsOf(context);
      final phase = ((_arrival - i * .07) / .45).clamp(0.0, 1.0);
      final bounce = quiet ? 0.0 : math.sin(phase * math.pi) * (1 - phase);
      canvas.save();
      canvas.translate(x, cy + 70);
      canvas.scale(1 + bounce * .09);
      canvas.translate(-x, -cy - 70);
      final color = [
        MenuPalette.gold,
        MenuPalette.coral,
        MenuPalette.forest,
      ][i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(0, 3),
          const Radius.circular(17),
        ),
        Paint()..color = const Color(0x3325384A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(17)),
        Paint()..color = color,
      );
      TextPaint(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: i == 0 ? MenuPalette.ink : Colors.white,
        ),
      ).render(
        canvas,
        ['Retry', 'Home', 'Revive'][i],
        Vector2(x, cy + 70),
        anchor: Anchor.center,
      );
      canvas.restore();
    }
  }
}
