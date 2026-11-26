import 'package:flutter/material.dart';
import '../../game/dino_game.dart';
import 'adventure_panels.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';

class PauseMenu extends StatelessWidget {
  final DinoGame game;
  const PauseMenu({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    final stage = game.biomeManager.currentStage;
    return AdventurePanel(
      title: 'Paused',
      maxWidth: 420,
      maxHeight: 258,
      accent: MenuPalette.slate,
      symbol: MenuSymbol.play,
      subtitle: 'Take a little breather.',
      stage: stage,
      onClose: game.resumeGame,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 388),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF283B55), Color(0xFF192639)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFCFA55C), width: 1.5),
                    boxShadow: const [BoxShadow(color: Color(0x35101824), offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      EpochEmblem(stage: stage, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Score ${game.score.toInt()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Fredoka',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '+${game.coinManager.runCoins} coins',
                        style: const TextStyle(
                          color: MenuPalette.gold,
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: MenuAction(
                    symbol: MenuSymbol.play,
                    label: 'Continue',
                    color: const Color(0xFF136C51),
                    prominent: true,
                    onPressed: game.resumeGame,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: MenuAction(
                        symbol: MenuSymbol.settings,
                        label: 'Settings',
                        color: MenuPalette.slate,
                        onPressed: () => game.overlays.add('SettingsDialog'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MenuAction(
                        symbol: MenuSymbol.home,
                        label: 'Main menu',
                        color: MenuPalette.terracotta,
                        onPressed: game.exitToMenu,
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
  }
}
