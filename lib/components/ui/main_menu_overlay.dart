import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import '../../managers/audio_manager.dart';
import '../../skins/skin_registry.dart';
import 'adventure_panels.dart';
import 'minimal_home.dart';
import 'adventure_toast.dart';
import 'settings_dialog.dart';

class MainMenuOverlay extends StatefulWidget {
  final DinoGame game;
  const MainMenuOverlay({super.key, required this.game});
  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay>
    with SingleTickerProviderStateMixin {
  final focus = FocusNode();
  late final AnimationController _departure = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  bool _leaving = false;
  bool _panelOpen = false;
  int selected = 0;
  static const stages = [0, 1, 2, 3, 5, 4];
  static const names = [
    'Ancient Desert',
    'Jurassic Monsoon',
    'Primeval Forest',
    'Glacial Tundra',
    'Cosmic Orbit',
    'Volcano Inferno',
  ];
  static const icons = [
    Icons.wb_sunny_outlined,
    Icons.water_drop_outlined,
    Icons.park_outlined,
    Icons.ac_unit_outlined,
    Icons.rocket_launch_outlined,
    Icons.local_fire_department_outlined,
  ];
  @override
  void initState() {
    super.initState();
    selected = stages.indexOf(widget.game.biomeManager.currentStage % 6);
    if (selected < 0) selected = 0;
  }

  @override
  void dispose() {
    _departure.dispose();
    focus.dispose();
    super.dispose();
  }

  void select(int index) {
    if (_leaving || _panelOpen || index == selected) return;
    setState(() => selected = index);
    widget.game.biomeManager.currentStage = stages[index];
    widget.game.biomeManager.progress = 0;
    widget.game.biomeManager.isTransitioning = false;
    AudioManager.playButton();
  }

  void play() {
    if (_leaving || _panelOpen || widget.game.overlays.isActive('SettingsDialog')) return;
    setState(() => _leaving = true);
    AudioManager.playJump();
    widget.game.startGame(
      startingStage: stages[selected],
      authoredDesert:
          stages[selected] == 0 && !widget.game.coinManager.hasSeenTutorial,
      keepMenuOverlay: true,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.game.overlays.remove('MainMenuOverlay');
      return;
    }
    _departure.reverse().then((_) {
      if (mounted) widget.game.overlays.remove('MainMenuOverlay');
    });
  }

  Future<void> open(Widget panel) async {
    if (_leaving || _panelOpen) return;
    _panelOpen = true;
    widget.game.menuPanelOpen = true;
    AudioManager.playButton();
    try {
      await showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      pageBuilder: (_, animation, secondaryAnimation) => panel,
      transitionBuilder: (_, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0, .035),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          ),
      );
    } finally {
      widget.game.menuPanelOpen = false;
      _panelOpen = false;
      if (mounted) {
        setState(() {});
        focus.requestFocus();
      }
    }
  }

  void gift() {
    final reward = widget.game.coinManager.claimDailyReward(rewardCoins: 150);
    if (reward == 0) return;
    setState(() {});
    AudioManager.playCoin();
    showAdventureToast(context, 'Daily gift · +$reward coins', bottom: 76);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.game.state != GameState.menu && !_leaving) {
      return const SizedBox.shrink();
    }
    final wallet = widget.game.coinManager;
    return KeyboardListener(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: (event) {
        if (_leaving || _panelOpen || widget.game.overlays.isActive('SettingsDialog')) return;
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
        // Focused buttons own Enter/Space; do not activate Play as well.
        if (!focus.hasPrimaryFocus) return;
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          play();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
            selected > 0) {
          select(selected - 1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
            selected < names.length - 1) {
          select(selected + 1);
        }
      },
      child: IgnorePointer(
        ignoring: _leaving,
        child: FadeTransition(
          opacity: _departure,
          child: MinimalHome(
            skin: SkinRegistry.defaultSkin,
            coins: wallet.coins,
            best: wallet.highScore,
            selected: selected,
            stage: stages[selected],
            names: names,
            icons: icons,
            onPlay: play,
            onSelect: select,
            onGift: wallet.canClaimDailyReward ? gift : null,
            onWardrobe: () => open(AdventureWardrobe(game: widget.game)),
            onUpgrades: () => open(AdventureUpgrades(game: widget.game)),
            onJournal: () => open(AdventureJournal(game: widget.game)),
            onSettings: () => open(SettingsDialog(
              stage: stages[selected],
              onClose: () => Navigator.of(context).pop(),
            )),
          ),
        ),
      ),
    );
  }
}
