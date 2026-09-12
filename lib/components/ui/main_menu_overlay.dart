import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/dino_game.dart';
import '../../skins/skin_registry.dart';
import '../../skins/skin.dart';
import '../../managers/audio_manager.dart';

/// 🌌 The Next-Gen Futuristic Main Menu Overlay for Dino Run Epochs.
/// Layered seamlessly over Flame canvas with real-time runner preview,
/// starting realm selector, upgrades tree, missions, and wardrobe.
class MainMenuOverlay extends StatefulWidget {
  final DinoGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _runnerAnimController;
  late Animation<double> _pulseAnimation;
  final FocusNode _focusNode = FocusNode();

  int _selectedRealmIndex = 0;
  int _selectedSkinIndex = 0;

  final List<Map<String, dynamic>> _realms = [
    {
      'name': 'Ancient Desert',
      'tag': 'STARTING REALM',
      'badge': 'TODAY',
      'icon': Icons.wb_sunny_outlined,
      'color': const Color(0xFFEAA63F),
      'stage': 0,
      'bonus': '+50% COINS',
    },
    {
      'name': 'Jurassic Monsoon',
      'tag': 'HYDROPLANING',
      'badge': null,
      'icon': Icons.water_drop_outlined,
      'color': const Color(0xFF64B5F6),
      'stage': 1,
      'bonus': 'RAIN STORMS',
    },
    {
      'name': 'Primeval Forest',
      'tag': 'HIGH CANOPY',
      'badge': null,
      'icon': Icons.park_outlined,
      'color': const Color(0xFF81C784),
      'stage': 2,
      'bonus': 'MEGA FLORA',
    },
    {
      'name': 'Glacial Tundra',
      'tag': 'ICE SPIKES',
      'badge': null,
      'icon': Icons.ac_unit_outlined,
      'color': const Color(0xFF80DEEA),
      'stage': 3,
      'bonus': 'ICE HAZARDS',
    },
    {
      'name': 'Cosmic Orbit',
      'tag': 'ZERO-G FLIGHT',
      'badge': 'SPECIAL',
      'icon': Icons.rocket_launch_outlined,
      'color': const Color(0xFFB388FF),
      'stage': 5,
      'bonus': 'COSMIC COINS',
    },
    {
      'name': 'Volcano Inferno',
      'tag': 'MAGMA HAZARDS',
      'badge': null,
      'icon': Icons.local_fire_department_outlined,
      'color': const Color(0xFFFF7043),
      'stage': 4,
      'bonus': 'LAVA GEYSERS',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Continuous 8 FPS runner animation ticker
    _runnerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();

    // Sync selected skin with current active skin
    final currentSkinId = widget.game.coinManager.activeSkinId;
    final allSkins = SkinRegistry.all;
    final idx = allSkins.indexWhere((s) => s.id == currentSkinId);
    if (idx != -1) {
      _selectedSkinIndex = idx;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _runnerAnimController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onStartExpedition() {
    AudioManager.playJump();
    final stage = _realms[_selectedRealmIndex]['stage'] as int;
    widget.game.startGame(startingStage: stage);
  }

  void _claimDailyReward() {
    if (!widget.game.coinManager.canClaimDailyReward) return;
    setState(() {
      widget.game.coinManager.claimDailyReward(rewardCoins: 150);
    });
    AudioManager.playCoin();
  }

  void _selectRealm(int index) {
    setState(() {
      _selectedRealmIndex = index;
    });
    final stage = _realms[index]['stage'] as int;
    widget.game.biomeManager.currentStage = stage;
    widget.game.biomeManager.progress = 0.0;
    widget.game.biomeManager.isTransitioning = false;
    AudioManager.playButton();
  }

  void _nextSkin() {
    final allSkins = SkinRegistry.all;
    setState(() {
      _selectedSkinIndex = (_selectedSkinIndex + 1) % allSkins.length;
      final newSkin = allSkins[_selectedSkinIndex];
      widget.game.player.setSkin(newSkin);
    });
    AudioManager.playButton();
  }

  void _prevSkin() {
    final allSkins = SkinRegistry.all;
    setState(() {
      _selectedSkinIndex = (_selectedSkinIndex - 1 + allSkins.length) % allSkins.length;
      final newSkin = allSkins[_selectedSkinIndex];
      widget.game.player.setSkin(newSkin);
    });
    AudioManager.playButton();
  }

  void _claimMission(int missionId, int rewardCoins) {
    if (widget.game.coinManager.isMissionClaimed(missionId)) return;
    setState(() {
      widget.game.coinManager.claimMission(missionId, rewardCoins);
    });
    AudioManager.playCoin();
  }

  void _openUpgrades() {
    AudioManager.playButton();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _UpgradesDialog(game: widget.game),
    ).then((_) => setState(() {}));
  }

  void _openSkins() {
    AudioManager.playButton();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _SkinsDialog(
        game: widget.game,
        onSkinSelected: (skin) {
          final idx = SkinRegistry.all.indexWhere((s) => s.id == skin.id);
          if (idx != -1) {
            setState(() {
              _selectedSkinIndex = idx;
            });
          }
        },
      ),
    ).then((_) => setState(() {}));
  }

  void _openTimeCodex() {
    AudioManager.playButton();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => const _TimeCodexDialog(),
    );
  }

  void _openTutorial() {
    AudioManager.playButton();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => const _TutorialDialog(),
    );
  }

  void _openSettings() {
    AudioManager.playButton();
    widget.game.overlays.add('SettingsDialog');
  }

  void _triggerDinoRoarEasterEgg() {
    AudioManager.playJump();
    widget.game.coinManager.addCoins(10);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🦖 ', style: TextStyle(fontSize: 18)),
            Text(
              'ROAAARRR! Secret Prehistoric Fossil Found! +10 Coins',
              style: TextStyle(color: Color(0xFFFEF08A), fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final coinManager = widget.game.coinManager;
    final coins = coinManager.coins;
    final hiScore = coinManager.highScore;
    final allSkins = SkinRegistry.all;
    final currentSkin = allSkins.isNotEmpty ? allSkins[_selectedSkinIndex] : SkinRegistry.defaultSkin;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isPortrait = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            _onStartExpedition();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _prevSkin();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextSkin();
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark futuristic backdrop allowing background scenery to peek through softly
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.35,
                    colors: [
                      Color(0x33060814),
                      Color(0x7703040A),
                      Color(0xBB020205),
                    ],
                  ),
                ),
              ),
            ),

            // Main Menu Layout
            SafeArea(
              child: Column(
                children: [
                  // 1. Top Header Bar
                  _buildTopBar(coins),

                  // 2. Main 3-Column Content Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isPortrait = constraints.maxHeight > constraints.maxWidth;
                          if (constraints.maxWidth < 800) {
                            // On mobile, just return the center stage so it takes exact remaining space.
                            // The left panel (Claimable widget) is already floating via a Stack.
                            return _buildCenterStage(currentSkin);
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Panel (Expeditions & Realm Selector)
                                SizedBox(
                                  width: 275,
                                  child: _buildLeftPanel(),
                                ),
                                const SizedBox(width: 12),
                                // Center Stage (Runner Preview & Start Action)
                                Expanded(
                                  child: _buildCenterStage(currentSkin),
                                ),
                                const SizedBox(width: 12),
                                // Right Panel (Active Missions & Records)
                                SizedBox(
                                  width: 275,
                                  child: _buildRightPanel(coins, hiScore),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  // 3. Footer Keybind Hints
                  _buildFooter(),
                ],
              ),
            ),

            // Floating Claimable widget on Mobile
            if (isMobile)
              Positioned(
                top: 80,
                left: 16,
                child: SizedBox(
                  width: 220,
                  child: _buildLeftPanel(),
                ),
              ),

            // Floating Start Button on Mobile
            if (isMobile)
              Positioned(
                bottom: 24,
                right: 24,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _onStartExpedition,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5 + _pulseAnimation.value * 0.3),
                                blurRadius: 10 + _pulseAnimation.value * 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 18),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP BAR
  // -------------------------------------------------------------
  Widget _buildTopBar(int coins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/app_icon.png', width: 38, height: 38),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'DINO RUN',
                        style: TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(color: Color(0xFF22C55E), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA78BFA), width: 0.8),
                        ),
                        child: const Text(
                          'EPOCHS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'INFINITE TIME ODYSSEY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right Actions (Coins, Upgrades, Settings)
          Row(
            children: [
              // Coins Counter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33F59E0B), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFCD34D), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Upgrades Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openUpgrades,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF475569), width: 1),
                    ),
                    child: const Icon(Icons.bolt, color: Color(0xFFCBD5E1), size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Skins Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openSkins,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF475569), width: 1),
                    ),
                    child: const Icon(Icons.checkroom, color: Color(0xFFCBD5E1), size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Settings Gear Icon
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openSettings,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF475569), width: 1),
                    ),
                    child: const Icon(Icons.settings, color: Color(0xFFCBD5E1), size: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LEFT PANEL (Expeditions & Realm Selector)
  // -------------------------------------------------------------
  Widget _buildLeftPanel() {
    final canClaimDaily = widget.game.coinManager.canClaimDailyReward;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Daily Supply Drop Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330284C7),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DAILY SUPPLY DROP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '+150 Coins & +8 Diamonds',
                    style: TextStyle(
                      color: Color(0xFFBAE6FD),
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              MouseRegion(
                cursor: canClaimDaily ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canClaimDaily ? _claimDailyReward : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: canClaimDaily ? const Color(0xFFFEF08A) : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Color(0x44000000), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      canClaimDaily ? 'CLAIM' : 'CLAIMED',
                      style: TextStyle(
                        color: canClaimDaily ? const Color(0xFF78350F) : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // CENTER STAGE (Runner Preview & Start Action)
  // -------------------------------------------------------------
  Widget _buildCenterStage(CharacterSkin currentSkin) {
    final skinName = currentSkin.displayName.toUpperCase();
    final isUnlocked = widget.game.coinManager.isSkinUnlocked(currentSkin.id);
    final selectedRealm = _realms[_selectedRealmIndex];
    final selectedRealmColor = selectedRealm['color'] as Color;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isPortrait = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Banner: Active Epoch Selector Indicator & Runner Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active Epoch Pill (Tappable to cycle realms easily)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _selectRealm((_selectedRealmIndex + 1) % _realms.length);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selectedRealmColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selectedRealmColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: selectedRealmColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(selectedRealm['icon'] as IconData, color: selectedRealmColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'EPOCH: ${(selectedRealm['name'] as String).toUpperCase()} ❯',
                        style: TextStyle(
                          color: selectedRealmColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),

        // Character Showcase Stage
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [


              // Pedestal Platform & Live Animated Character
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Epic Starburst / Aura Effect (Behind Dino)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          width: 140 + _pulseAnimation.value * 20,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                currentSkin.primaryColor.withValues(alpha: 0.6 + _pulseAnimation.value * 0.4),
                                currentSkin.primaryColor.withValues(alpha: 0.2 + _pulseAnimation.value * 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentSkin.primaryColor.withValues(alpha: 0.5),
                                blurRadius: 40 + _pulseAnimation.value * 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. Rotating Tech/Magic Ring (Cooler and Thicker)
                  AnimatedBuilder(
                    animation: _runnerAnimController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: const Offset(0, 45),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002) // Perspective 3D
                            ..rotateX(1.3) // Tilt like a platform
                            ..rotateZ(_runnerAnimController.value * math.pi * 2), // Rotate constantly
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: currentSkin.primaryColor,
                                    width: 8.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentSkin.primaryColor,
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ]
                                ),
                              ),
                              // Draw an arc/dash to make rotation obvious
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: CircularProgressIndicator(
                                  value: 0.85,
                                  strokeWidth: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // 3. Epic Core Glow Platform
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: const Offset(0, 45),
                        child: Container(
                          width: 150 + _pulseAnimation.value * 20,
                          height: 40 + _pulseAnimation.value * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white,
                                currentSkin.primaryColor,
                                currentSkin.primaryColor.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentSkin.primaryColor.withValues(alpha: 0.8),
                                blurRadius: 50,
                                spreadRadius: 25,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Animated Dinosaur Preview on Pedestal
                  Transform.translate(
                    offset: const Offset(0, -15),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _triggerDinoRoarEasterEgg,
                        child: Tooltip(
                          message: 'Tap Dino for a surprise!',
                          child: SizedBox(
                            width: 80,
                            height: 96,
                            child: _SkinPreviewWidget(
                              skin: currentSkin,
                              ticker: _runnerAnimController,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Character Stats below
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Runner Name Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentSkin.primaryColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: currentSkin.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentSkin.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          skinName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status Badge (EQUIPPED / LOCKED)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUnlocked ? const Color(0xFF065F46) : const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isUnlocked)
                          const Icon(Icons.monetization_on, color: Color(0xFFFDE68A), size: 14),
                        if (!isUnlocked)
                          const SizedBox(width: 6),
                        Text(
                          isUnlocked ? 'EQUIPPED RUNNER' : '${currentSkin.price} TO UNLOCK',
                          style: TextStyle(
                            color: isUnlocked ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),


            ],
          ),
        ),
        ), // Close Expanded

        // Action Section (Big Start Button + Sub Buttons)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Big START EXPEDITION Button with Selected Realm Theme
            if (!isMobile)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onStartExpedition,
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            selectedRealmColor,
                            const Color(0xFFEA580C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFFFFF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedRealmColor.withValues(alpha: 0.5 + _pulseAnimation.value * 0.3),
                            blurRadius: 16 + _pulseAnimation.value * 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'PLAY: ${(selectedRealm['name'] as String).toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isMobile)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SPACE',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // RIGHT PANEL (Active Missions & Records)
  // -------------------------------------------------------------
  Widget _buildRightPanel(int coins, int hiScore) {
    final coinManager = widget.game.coinManager;
    final jumps = coinManager.totalJumps;
    final shieldHits = coinManager.shieldHits;
    final spaceTrips = coinManager.spaceTrips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech, color: Color(0xFF38BDF8), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'ACTIVE MISSIONS',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                '🏆 BEST: $hiScore',
                style: const TextStyle(
                  color: Color(0xFFFCD34D),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Mission Cards
        Expanded(
          child: ListView(
            children: [
              _buildMissionCard(
                id: 0,
                icon: Icons.monetization_on,
                iconColor: const Color(0xFFFCD34D),
                title: 'Collect 50 Coins',
                progressText: '$coins / 50',
                progress: (coins / 50).clamp(0.0, 1.0),
                rewardCoins: 50,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 1,
                icon: Icons.emoji_events,
                iconColor: const Color(0xFFFDE047),
                title: 'Reach 500 Best Score',
                progressText: '$hiScore / 500',
                progress: (hiScore / 500).clamp(0.0, 1.0),
                rewardCoins: 100,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 2,
                icon: Icons.security,
                iconColor: const Color(0xFF93C5FD),
                title: 'Survive 3 Shield Hits',
                progressText: '$shieldHits / 3',
                progress: (shieldHits / 3).clamp(0.0, 1.0),
                rewardCoins: 80,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 3,
                icon: Icons.bolt,
                iconColor: const Color(0xFFFCD34D),
                title: 'Perform 10 Jumps',
                progressText: '$jumps / 10',
                progress: (jumps / 10).clamp(0.0, 1.0),
                rewardCoins: 60,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 4,
                icon: Icons.rocket_launch,
                iconColor: const Color(0xFFFCA5A5),
                title: 'Enter Space Mode',
                progressText: '$spaceTrips / 1',
                progress: (spaceTrips / 1).clamp(0.0, 1.0),
                rewardCoins: 120,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard({
    required int id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String progressText,
    required double progress,
    required int rewardCoins,
  }) {
    final isClaimed = widget.game.coinManager.isMissionClaimed(id);
    final canClaim = progress >= 1.0 && !isClaimed;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canClaim ? const Color(0xFFF59E0B) : const Color(0xFF334155).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MouseRegion(
                cursor: canClaim ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canClaim ? () => _claimMission(id, rewardCoins) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isClaimed
                          ? const Color(0xFF1E293B)
                          : (canClaim ? const Color(0xFFF59E0B) : const Color(0xFF334155)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canClaim && !isClaimed) ...[
                          const Icon(Icons.monetization_on, color: Colors.black87, size: 10),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isClaimed ? 'CLAIMED' : (canClaim ? 'CLAIM $rewardCoins' : 'CLAIM'),
                          style: TextStyle(
                            color: isClaimed
                                ? const Color(0xFF64748B)
                                : (canClaim ? Colors.black87 : const Color(0xFF94A3B8)),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isClaimed ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progressText,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FOOTER (Keybinds)
  // -------------------------------------------------------------
  Widget _buildFooter() {
    final isMobile = MediaQuery.of(context).size.width < 800;
    if (isMobile) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        '■ [SPACE / UP / CLICK] JUMP & DOUBLE JUMP · [← / →] SWITCH SKINS · [P / ESC] PAUSE',
        style: TextStyle(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.7),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// LIVE RUNNER PREVIEW WIDGET
// -----------------------------------------------------------------

class _SkinPreviewWidget extends StatelessWidget {
  final CharacterSkin skin;
  final AnimationController ticker;

  const _SkinPreviewWidget({required this.skin, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ticker,
      builder: (context, child) {
        final frame = (ticker.value * 4).floor() % 4;
        return CustomPaint(
          size: const Size(80, 96),
          painter: _SkinPainter(skin: skin, frame: frame),
        );
      },
    );
  }
}

class _SkinPainter extends CustomPainter {
  final CharacterSkin skin;
  final int frame;

  _SkinPainter({required this.skin, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    skin.renderRunning(canvas, size, frame);
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) {
    return oldDelegate.skin.id != skin.id || oldDelegate.frame != frame;
  }
}

// -----------------------------------------------------------------
// DIALOGS: UPGRADES, SKINS, TIME CODEX, TUTORIAL
// -----------------------------------------------------------------

class _UpgradesDialog extends StatefulWidget {
  final DinoGame game;
  const _UpgradesDialog({required this.game});

  @override
  State<_UpgradesDialog> createState() => _UpgradesDialogState();
}

class _UpgradesDialogState extends State<_UpgradesDialog> {
  void _buyUpgrade(String upgradeId, int cost) {
    if (widget.game.coinManager.upgradePowerup(upgradeId, cost)) {
      AudioManager.playUpgrade();
      setState(() {});
    } else {
      AudioManager.playHit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final coinManager = widget.game.coinManager;
    final coins = coinManager.coins;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF818CF8), width: 1.5),
                          ),
                          child: const Icon(Icons.bolt, color: Color(0xFFC4B5FD), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'POWER-UP LAB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 20 : 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Text(
                              'ENHANCE YOUR ABILITIES',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33F59E0B), blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Color(0xFFFCD34D), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '$coins',
                                style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1, thickness: 1),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
                  child: GridView.count(
                    crossAxisCount: isMobile ? 1 : 4,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: isMobile ? 2.5 : 0.75,
                    children: [
                      _buildUpgradeCard(
                        upgradeId: 'magnet',
                        iconWidget: CustomPaint(size: const Size(50, 50), painter: _PowerupPainter('magnet')),
                        title: 'COIN MAGNET',
                        subtitle: 'Increases magnetic pull radius & duration.',
                        level: coinManager.magnetLevel,
                        context: context,
                        isMobile: isMobile,
                      ),
                      _buildUpgradeCard(
                        upgradeId: 'shield',
                        iconWidget: CustomPaint(size: const Size(50, 50), painter: _PowerupPainter('shield')),
                        title: 'ENERGY SHIELD',
                        subtitle: 'Longer duration & invincibility frames.',
                        level: coinManager.shieldLevel,
                        context: context,
                        isMobile: isMobile,
                      ),
                      _buildUpgradeCard(
                        upgradeId: 'cosmic',
                        iconWidget: CustomPaint(size: const Size(50, 50), painter: _PowerupPainter('cosmic')),
                        title: 'ROCKET THRUSTER',
                        subtitle: 'Higher points & bonus cosmic coins.',
                        level: coinManager.cosmicLevel,
                        context: context,
                        isMobile: isMobile,
                      ),
                      _buildUpgradeCard(
                        upgradeId: 'multiplier',
                        iconWidget: CustomPaint(size: const Size(50, 50), painter: _PowerupPainter('multiplier')),
                        title: 'LUCKY MULTIPLIER',
                        subtitle: 'Higher chance of double coin spawns.',
                        level: coinManager.multiplierLevel,
                        context: context,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String upgradeId,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required int level,
    required BuildContext context,
    required bool isMobile,
  }) {
    final costs = [500, 1000, 2500, 5000, 10000];
    final isMax = level >= 5;
    final nextCost = isMax ? 0 : costs[level];
    final canAfford = !isMax && widget.game.coinManager.coins >= nextCost;

    if (isMobile) {
      // Horizontal layout for mobile
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF475569), width: 1.5),
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = index < level;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isActive ? const Color(0xFF10B981) : const Color(0xFF334155),
                            boxShadow: isActive ? const [BoxShadow(color: Color(0x6610B981), blurRadius: 4)] : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMax
                      ? const Color(0xFF064E3B)
                      : (canAfford ? const Color(0xFFF59E0B) : const Color(0xFF1E293B)),
                  foregroundColor: isMax
                      ? const Color(0xFF34D399)
                      : (canAfford ? Colors.black87 : Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isMax ? const Color(0xFF059669) : (canAfford ? Colors.transparent : const Color(0xFF334155)),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: canAfford && !isMax ? 4 : 0,
                ),
                onPressed: canAfford ? () => _buyUpgrade(upgradeId, nextCost) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isMax ? 'MAX' : 'UPGRADE',
                      style: TextStyle(
                        fontSize: isMax ? 11 : 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!isMax) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$nextCost',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Vertical layout for desktop/tablet
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF475569), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.2), blurRadius: 20),
              ],
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isActive = index < level;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive ? const Color(0xFF10B981) : const Color(0xFF334155),
                    boxShadow: isActive ? const [BoxShadow(color: Color(0x6610B981), blurRadius: 6)] : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isMax
                    ? const Color(0xFF064E3B)
                    : (canAfford ? const Color(0xFFF59E0B) : const Color(0xFF1E293B)),
                foregroundColor: isMax
                    ? const Color(0xFF34D399)
                    : (canAfford ? Colors.black87 : Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isMax ? const Color(0xFF059669) : (canAfford ? Colors.transparent : const Color(0xFF334155)),
                  ),
                ),
                elevation: canAfford && !isMax ? 8 : 0,
                padding: EdgeInsets.zero,
              ),
              onPressed: canAfford ? () => _buyUpgrade(upgradeId, nextCost) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isMax ? 'MAXIMUM LEVEL' : 'UPGRADE',
                    style: TextStyle(
                      fontSize: isMax ? 13 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (!isMax) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on, size: 14, color: canAfford ? Colors.black87 : const Color(0xFFFCD34D)),
                          const SizedBox(width: 4),
                          Text(
                            '$nextCost',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinsDialog extends StatefulWidget {
  final DinoGame game;
  final Function(CharacterSkin) onSkinSelected;

  const _SkinsDialog({required this.game, required this.onSkinSelected});

  @override
  State<_SkinsDialog> createState() => _SkinsDialogState();
}

class _SkinsDialogState extends State<_SkinsDialog> {
  void _buySkin(CharacterSkin skin) {
    if (widget.game.coinManager.tryPurchaseSkin(skin.id, skin.price)) {
      widget.game.player.setSkin(skin);
      widget.onSkinSelected(skin);
      AudioManager.playUpgrade();
      setState(() {});
    } else {
      AudioManager.playHit();
    }
  }

  void _equipSkin(CharacterSkin skin) {
    widget.game.player.setSkin(skin);
    widget.onSkinSelected(skin);
    AudioManager.playButton();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final skins = SkinRegistry.all;
    final coinManager = widget.game.coinManager;
    final coins = coinManager.coins;

    return Material(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.25), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checkroom, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'CHARACTER SKINS',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                        ),
                        child: Text(
                          '🪙 $coins',
                          style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                        onPressed: () => Navigator.of(context).pop(), // If it's a dialog
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: skins.map((s) {
                      final isEquipped = widget.game.player.skin.id == s.id;
                      final isUnlocked = coinManager.isSkinUnlocked(s.id);
                      final canAfford = coins >= s.price;

                      return Container(
                        width: 170,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEquipped ? const Color(0xFF38BDF8) : const Color(0xFF475569),
                            width: isEquipped ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Rarity badge
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: s.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: s.primaryColor, width: 0.6),
                                ),
                                child: Text(
                                  s.rarity,
                                  style: TextStyle(color: s.primaryColor, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Skin Preview Canvas
                            SizedBox(
                              width: 50,
                              height: 60,
                              child: CustomPaint(
                                painter: _SkinPainter(skin: s, frame: 0),
                              ),
                            ),
                            const SizedBox(height: 6),

                            Text(
                              s.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),

                            if (s.id != 'rive_dino')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF334155),
                                  foregroundColor: const Color(0xFF64748B),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: null,
                                child: const Text('LOCKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                              )
                            else if (isUnlocked)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEquipped ? const Color(0xFF0284C7) : const Color(0xFF334155),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: isEquipped ? null : () => _equipSkin(s),
                                child: Text(
                                  isEquipped ? 'EQUIPPED' : 'EQUIP',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canAfford ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                                  foregroundColor: canAfford ? Colors.black87 : const Color(0xFF64748B),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: canAfford ? () => _buySkin(s) : null,
                                child: Text(
                                  '🪙 ${s.price}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeCodexDialog extends StatelessWidget {
  const _TimeCodexDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.menu_book, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 8),
                Text(
                  'THE TIME CODEX — EPOCHS OF EARTH',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Run across millions of years in Dino Run Epochs! Every 4,500 points traveled seamlessly shifts your world across eras:\n\n'
              '• 🏜️ Ancient Desert: Stepped stone pyramids, ancient sphinx monuments & gold dust\n'
              '• 🌧️ Jurassic Monsoon: Torrential rainstorms & water hazards\n'
              '• 🌲 Primeval Forest: Ancient megaflora & towering canopies\n'
              '• ❄️ Glacial Tundra: Ice age blizzards & razor glacier spikes\n'
              '• 🌋 Volcano Inferno: Magma flows & volcanic falling rocks\n'
              '• 🌌 Cosmic Orbit: Zero-G rocket powerups in the outer atmosphere',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5, height: 1.45),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black87,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE CODEX', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialDialog extends StatelessWidget {
  const _TutorialDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Color(0xFF38BDF8), size: 20),
                SizedBox(width: 8),
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Jump: Tap Screen or Press [SPACE / UP]\n'
              '• Double Jump: Press Jump again while in mid-air\n'
              '• Pause: Press [P / ESC] or tap top Pause bar\n'
              '• Collect 🪙 Coins to purchase power-up upgrades & unlock skins\n'
              '• Grab 🧲 Magnets to pull in nearby treasures\n'
              '• Grab 🛡️ Shields to survive collision hazards\n'
              '• Grab 🚀 Rockets to enter Zero-G Space Bonus Mode!\n'
              '• Grab ⚡ Giant Dino to grow massive & smash obstacles!',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GOT IT!', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerupPainter extends CustomPainter {
  final String upgradeId;
  _PowerupPainter(this.upgradeId);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final floatOffset = 1.0; // Static offset for rendering

    if (upgradeId == 'magnet') {
      // 1. Magnetic Field Glow
      canvas.drawCircle(
        Offset(cx, cy),
        22,
        Paint()..color = const Color(0xFFAB47BC).withValues(alpha: 0.30),
      );

      // 2. Circular Purple Container Badge
      final badgeRect = Rect.fromCircle(center: Offset(cx, cy), radius: 19);
      canvas.drawCircle(Offset(cx, cy), 19, Paint()..shader = const RadialGradient(colors: [Color(0xFF8E24AA), Color(0xFF4A148C)]).createShader(badgeRect));
      canvas.drawCircle(Offset(cx, cy), 19, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.8);

      // 3. Horseshoe Magnet U-Shape
      final uPath = Path()
        ..moveTo(cx - 10, cy - 8)
        ..lineTo(cx - 10, cy + 3)
        ..cubicTo(cx - 10, cy + 13, cx + 10, cy + 13, cx + 10, cy + 3)
        ..lineTo(cx + 10, cy - 8)
        ..lineTo(cx + 5, cy - 8)
        ..lineTo(cx + 5, cy + 3)
        ..cubicTo(cx + 5, cy + 8, cx - 5, cy + 8, cx - 5, cy + 3)
        ..lineTo(cx - 5, cy - 8)
        ..close();

      // Red North Arm (Left)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(cx - 12, cy - 10, 12, 25));
      canvas.drawPath(uPath, Paint()..color = const Color(0xFFE53935));
      canvas.restore();

      // Blue South Arm (Right)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(cx, cy - 10, 12, 25));
      canvas.drawPath(uPath, Paint()..color = const Color(0xFF1E88E5));
      canvas.restore();

      // Silver Pole Tips
      final tipPaint = Paint()..color = const Color(0xFFECEFF1);
      canvas.drawRect(Rect.fromLTWH(cx - 10, cy - 9, 5, 4), tipPaint);
      canvas.drawRect(Rect.fromLTWH(cx + 5, cy - 9, 5, 4), tipPaint);

      // Magnetic Force Spark Arcs between tips
      final arcPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final arcPath = Path()
        ..moveTo(cx - 7, cy - 11)
        ..quadraticBezierTo(cx, cy - 15 + math.sin(floatOffset * 8) * 2, cx + 7, cy - 11);
      canvas.drawPath(arcPath, arcPaint);
    } else if (upgradeId == 'shield') {
      // 1. Protective Cyan Energy Glow
      canvas.drawCircle(
        Offset(cx, cy),
        22,
        Paint()..color = const Color(0xFF29B6F6).withValues(alpha: 0.30),
      );

      // 2. Shield Body Path
      final shieldPath = Path()
        ..moveTo(cx, cy - 16)
        ..lineTo(cx + 14, cy - 16)
        ..quadraticBezierTo(cx + 15, cy + 2, cx, cy + 17)
        ..quadraticBezierTo(cx - 15, cy + 2, cx - 14, cy - 16)
        ..close();

      final shieldGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0288D1), Color(0xFF01579B)],
      );
      final shieldRect = Rect.fromLTWH(cx - 15, cy - 16, 30, 33);
      canvas.drawPath(shieldPath, Paint()..shader = shieldGradient.createShader(shieldRect));

      // Golden Rim Border
      final borderPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawPath(shieldPath, borderPaint);

      // Golden Star Emblem in Center
      final starPath = Path();
      for (int i = 0; i < 5; i++) {
        final aOuter = (i * 72 - 90) * math.pi / 180;
        final aInner = ((i + 0.5) * 72 - 90) * math.pi / 180;
        final rO = 6.5;
        final rI = 2.8;
        if (i == 0) {
          starPath.moveTo(cx + math.cos(aOuter) * rO, cy - 1 + math.sin(aOuter) * rO);
        } else {
          starPath.lineTo(cx + math.cos(aOuter) * rO, cy - 1 + math.sin(aOuter) * rO);
        }
        starPath.lineTo(cx + math.cos(aInner) * rI, cy - 1 + math.sin(aInner) * rI);
      }
      starPath.close();
      canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD700));
    } else if (upgradeId == 'cosmic') {
      // 1. Pulsing thruster energy aura glow
      final auraRadius = 20.0 + math.sin(floatOffset * 3) * 2.0;
      canvas.drawCircle(
        Offset(cx, cy),
        auraRadius + 5,
        Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.30),
      );

      // 2. Circular Cyan/Blue Powerup Container Badge
      final badgeGradient = const RadialGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF00838F), Color(0xFF004D40)],
      );
      canvas.drawCircle(Offset(cx, cy), 19, Paint()..shader = badgeGradient.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 19)));
      canvas.drawCircle(Offset(cx, cy), 19, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.8);

      // 3. Rocket Thruster Exhaust Flame (Bottom)
      final flamePath = Path()
        ..moveTo(cx - 5, cy + 8)
        ..quadraticBezierTo(cx, cy + 17 + math.sin(floatOffset * 10) * 3, cx + 5, cy + 8)
        ..close();
      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF9100));
      canvas.drawCircle(Offset(cx, cy + 10), 3.0, Paint()..color = const Color(0xFFFFFF00));

      // 4. Sleek Metallic Rocket Body
      final rocketPath = Path()
        ..moveTo(cx, cy - 14)
        ..cubicTo(cx + 9, cy - 8, cx + 8, cy + 8, cx + 6, cy + 10)
        ..lineTo(cx - 6, cy + 10)
        ..cubicTo(cx - 8, cy + 8, cx - 9, cy - 8, cx, cy - 14)
        ..close();

      final rocketGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFCFD8DC), Color(0xFF78909C)],
      );
      canvas.drawPath(rocketPath, Paint()..shader = rocketGradient.createShader(Rect.fromLTWH(cx - 9, cy - 14, 18, 24)));

      // Rocket Nose Cone (Red)
      final nosePath = Path()
        ..moveTo(cx, cy - 14)
        ..lineTo(cx + 5, cy - 5)
        ..lineTo(cx - 5, cy - 5)
        ..close();
      canvas.drawPath(nosePath, Paint()..color = const Color(0xFFFF1744));

      // Rocket Wings / Fins (Left & Right)
      canvas.drawPath(
        Path()..moveTo(cx - 5, cy + 3)..lineTo(cx - 10, cy + 9)..lineTo(cx - 5, cy + 8)..close(),
        Paint()..color = const Color(0xFFFF1744),
      );
      canvas.drawPath(
        Path()..moveTo(cx + 5, cy + 3)..lineTo(cx + 10, cy + 9)..lineTo(cx + 5, cy + 8)..close(),
        Paint()..color = const Color(0xFFFF1744),
      );

      // Circular Porthole Window
      canvas.drawCircle(Offset(cx, cy - 1), 3.0, Paint()..color = const Color(0xFF00B0FF));
      canvas.drawCircle(Offset(cx - 0.8, cy - 1.8), 1.0, Paint()..color = Colors.white);
    } else if (upgradeId == 'multiplier') {
      // 1. Expanding Aura Glow
      final glowRadius = 20.0 + math.sin(floatOffset * 4) * 3.0;
      canvas.drawCircle(
        Offset(cx, cy),
        glowRadius,
        Paint()..color = const Color(0xFFFF4081).withValues(alpha: 0.35),
      );

      // 2. Purple Badge
      final badgeRect = Rect.fromCircle(center: Offset(cx, cy), radius: 19);
      canvas.drawCircle(Offset(cx, cy), 19, Paint()..shader = const RadialGradient(colors: [Color(0xFFD81B60), Color(0xFF880E4F)]).createShader(badgeRect));
      canvas.drawCircle(Offset(cx, cy), 19, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2.0);

      // 3. Mega Golden 5-Pointed Star
      final starPath = Path();
      for (int i = 0; i < 5; i++) {
        final aOuter = (i * 72 - 90) * math.pi / 180;
        final aInner = ((i + 0.5) * 72 - 90) * math.pi / 180;
        final rO = 12.0;
        final rI = 5.2;
        if (i == 0) {
          starPath.moveTo(cx + math.cos(aOuter) * rO, cy + math.sin(aOuter) * rO);
        } else {
          starPath.lineTo(cx + math.cos(aOuter) * rO, cy + math.sin(aOuter) * rO);
        }
        starPath.lineTo(cx + math.cos(aInner) * rI, cy + math.sin(aInner) * rI);
      }
      starPath.close();
      canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD700));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
