import 'package:flutter/material.dart';
import 'dart:ui';
import '../../game/dino_game.dart';
import '../../utils/colors.dart';

class PauseMenu extends StatelessWidget {
  final DinoGame game;

  const PauseMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GameColors.uiGreen.withValues(alpha: 0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 32,
                    color: GameColors.uiGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                _buildButton('CONTINUE', () {
                  game.resumeGame();
                }),
                const SizedBox(height: 16),
                _buildButton('SETTINGS', () {
                  game.overlays.add('SettingsDialog');
                }),
                const SizedBox(height: 16),
                _buildButton('EXIT', () {
                  game.exitToMenu();
                }, color: GameColors.uiRed),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color color = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color == Colors.white ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.2),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
