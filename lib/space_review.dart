// Isolated, in-memory flight review. Run with -t lib/space_review.dart.
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'components/ui/adventure_theme.dart';
import 'components/ui/main_menu_overlay.dart';
import 'game/dino_game.dart';
import 'managers/audio_manager.dart';
import 'managers/coin_manager.dart';

class _ReviewCoins extends CoinManager {
  int _earned = 0;
  @override
  int get coins => _earned;
  @override
  int get runCoins => _earned;
  @override
  int get collectedCoins => _earned;
  @override
  void addCoins(int amount) {
    _earned += amount;
  }

  @override
  void collectCoins(int amount) {
    _earned += amount;
  }

  @override
  void recordSpaceTrip() {}
  @override
  void recordJump() {}
  @override
  void updateHighScore(int score) {}
  @override
  Future<void> forceSave() async {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AudioManager.setVolume(0);
  runApp(
    MaterialApp(
      theme: AdventureTheme.data,
      debugShowCheckedModeBanner: false,
      home: const _Review(),
    ),
  );
}

class _Review extends StatefulWidget {
  const _Review();
  @override
  State<_Review> createState() => _ReviewState();
}

class _ReviewState extends State<_Review> {
  late final game = DinoGame(coinManager: _ReviewCoins());
  void launch() {
    if (!game.isLoaded) return;
    game.startGame();
    game.spawnManager.obstacleTimer = 999;
    game.spawnManager.coinTimer = 0;
    game.enterSpaceMode();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Space / menu review · isolated session'),
              TextButton(onPressed: launch, child: const Text('Launch trip')),
              TextButton(
                onPressed: () {
                  if (game.isLoaded) game.exitToMenu();
                },
                child: const Text('Menu'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GameWidget(
            game: game,
            initialActiveOverlays: const ['MainMenuOverlay'],
            overlayBuilderMap: {
              'MainMenuOverlay': (_, game) =>
                  MainMenuOverlay(game: game as DinoGame),
            },
          ),
        ),
      ],
    ),
  );
}
