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

  @override
  Widget build(BuildContext context) {
    final coinManager = widget.game.coinManager;
    final coins = coinManager.coins;
    final hiScore = coinManager.highScore;
    final allSkins = SkinRegistry.all;
    final currentSkin = allSkins.isNotEmpty ? allSkins[_selectedSkinIndex] : SkinRegistry.defaultSkin;

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
                      child: Row(
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
                      ),
                    ),
                  ),

                  // 3. Footer Keybind Hints
                  _buildFooter(),
                ],
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x664F46E5),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🦖', style: TextStyle(fontSize: 20)),
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
                    const Text('🪙', style: TextStyle(fontSize: 14)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA78BFA), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x557C3AED),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'UPGRADES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
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
              const Expanded(
                child: Column(
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
              ),
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
        const SizedBox(height: 8),

        // Realm Selection Header
        const Text(
          'SELECT STARTING REALM',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),

        // Realms List with crisp click handling
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: List.generate(_realms.length, (index) {
                final r = _realms[index];
                final isSelected = index == _selectedRealmIndex;
                final realmColor = r['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectRealm(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E293B).withValues(alpha: 0.98)
                              : const Color(0xFF0F172A).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? realmColor : const Color(0xFF334155).withValues(alpha: 0.5),
                            width: isSelected ? 1.8 : 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: realmColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: realmColor.withValues(alpha: isSelected ? 0.3 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(r['icon'] as IconData, color: realmColor, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        r['name'] as String,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                          fontSize: 10,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                        ),
                                      ),
                                      if (r['badge'] != null) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF78350F),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            r['badge'] as String,
                                            style: const TextStyle(
                                              color: Color(0xFFFCD34D),
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${r['tag']} • ${r['bonus']}',
                                    style: TextStyle(
                                      color: isSelected ? realmColor : const Color(0xFF64748B),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: realmColor, size: 15)
                            else
                              const Icon(Icons.chevron_right, color: Color(0xFF475569), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Open Time Codex Button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openTimeCodex,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4F46E5), width: 0.8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, color: Color(0xFFA5B4FC), size: 12),
                  SizedBox(width: 6),
                  Text(
                    'OPEN TIME CODEX',
                    style: TextStyle(
                      color: Color(0xFFA5B4FC),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Banner: Active Epoch Selector Indicator & Runner Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active Epoch Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selectedRealmColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selectedRealmColor, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: selectedRealmColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selectedRealm['icon'] as IconData, color: selectedRealmColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'EPOCH: ${(selectedRealm['name'] as String).toUpperCase()} (${selectedRealm['tag']})',
                    style: TextStyle(
                      color: selectedRealmColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Runner Name Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: currentSkin.primaryColor, width: 1.2),
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
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: currentSkin.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    skinName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Character Showcase Stage
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Chevron
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _prevSkin,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Pedestal Platform & Live Animated Character
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Pulsing Neon Ring
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 140 + _pulseAnimation.value * 12,
                        height: 40 + _pulseAnimation.value * 6,
                        margin: const EdgeInsets.only(top: 85),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentSkin.primaryColor.withValues(alpha: 0.4 + _pulseAnimation.value * 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: currentSkin.primaryColor.withValues(alpha: 0.25 + _pulseAnimation.value * 0.2),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Pedestal Disc Platform
                  Container(
                    width: 105,
                    height: 28,
                    margin: const EdgeInsets.only(top: 85),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      border: Border.all(color: currentSkin.primaryColor.withValues(alpha: 0.6), width: 1.2),
                    ),
                  ),

                  // Animated Dinosaur Preview on Pedestal
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 96,
                        child: _SkinPreviewWidget(
                          skin: currentSkin,
                          ticker: _runnerAnimController,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Status Badge (EQUIPPED / LOCKED)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isUnlocked ? const Color(0xFF065F46) : const Color(0xFF78350F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isUnlocked ? 'EQUIPPED RUNNER' : '🪙 ${currentSkin.price} TO UNLOCK',
                          style: TextStyle(
                            color: isUnlocked ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Right Chevron
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _nextSkin,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Action Section (Big Start Button + Sub Buttons)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Big START EXPEDITION Button with Selected Realm Theme
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

            const SizedBox(height: 8),

            // Secondary Buttons (Upgrades, Skins, Tutorial)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallAction('⚡ UPGRADES', const Color(0xFF7C3AED), _openUpgrades),
                const SizedBox(width: 8),
                _buildSmallAction('🩳 SKINS', const Color(0xFF334155), _openSkins),
                const SizedBox(width: 8),
                _buildSmallAction('🎓 TUTORIAL', const Color(0xFF0284C7), _openTutorial),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallAction(String title, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
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
                icon: '🪙',
                title: 'Collect 50 Coins',
                progressText: '$coins / 50',
                progress: (coins / 50).clamp(0.0, 1.0),
                rewardCoins: 50,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 1,
                icon: '🏆',
                title: 'Reach 500 Best Score',
                progressText: '$hiScore / 500',
                progress: (hiScore / 500).clamp(0.0, 1.0),
                rewardCoins: 100,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 2,
                icon: '🛡️',
                title: 'Survive 3 Shield Hits',
                progressText: '$shieldHits / 3',
                progress: (shieldHits / 3).clamp(0.0, 1.0),
                rewardCoins: 80,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 3,
                icon: '⚡',
                title: 'Perform 10 Jumps',
                progressText: '$jumps / 10',
                progress: (jumps / 10).clamp(0.0, 1.0),
                rewardCoins: 60,
              ),
              const SizedBox(height: 6),
              _buildMissionCard(
                id: 4,
                icon: '🚀',
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
    required String icon,
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
              Text(icon, style: const TextStyle(fontSize: 12)),
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
                    child: Text(
                      isClaimed ? 'CLAIMED' : (canClaim ? 'CLAIM 🪙$rewardCoins' : 'CLAIM'),
                      style: TextStyle(
                        color: isClaimed
                            ? const Color(0xFF64748B)
                            : (canClaim ? Colors.black87 : const Color(0xFF94A3B8)),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
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

    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x667C3AED), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, color: Color(0xFFA78BFA), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'POWER-UP UPGRADES TREE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
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
              ],
            ),
            const SizedBox(height: 16),

            _buildUpgradeRow(
              upgradeId: 'magnet',
              title: '🧲 Coin Magnet Booster',
              subtitle: 'Increases magnet pull radius (+30px) & duration (+2.0s)',
              level: coinManager.magnetLevel,
            ),
            const SizedBox(height: 10),
            _buildUpgradeRow(
              upgradeId: 'shield',
              title: '🛡️ Energy Shield Fortifier',
              subtitle: 'Longer shield duration (+2.0s) & post-hit invincibility (+0.4s)',
              level: coinManager.shieldLevel,
            ),
            const SizedBox(height: 10),
            _buildUpgradeRow(
              upgradeId: 'cosmic',
              title: '🚀 Cosmic Rocket Thruster',
              subtitle: 'Higher points (+40%) & bonus coins during Zero-G travel',
              level: coinManager.cosmicLevel,
            ),
            const SizedBox(height: 10),
            _buildUpgradeRow(
              upgradeId: 'multiplier',
              title: '✨ Lucky Coin Multiplier',
              subtitle: 'Increases chance of double coin value spawns (+20%)',
              level: coinManager.multiplierLevel,
            ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeRow({
    required String upgradeId,
    required String title,
    required String subtitle,
    required int level,
  }) {
    final costs = [100, 200, 350, 500, 750];
    final isMax = level >= 5;
    final nextCost = isMax ? 0 : costs[level];
    final canAfford = !isMax && widget.game.coinManager.coins >= nextCost;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    // Level Pips
                    Row(
                      children: List.generate(5, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < level ? const Color(0xFF10B981) : const Color(0xFF475569),
                          ),
                        );
                      }),
                    ),
                    Text(' Lv $level/5', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMax
                  ? const Color(0xFF065F46)
                  : (canAfford ? const Color(0xFFF59E0B) : const Color(0xFF334155)),
              foregroundColor: isMax
                  ? const Color(0xFF6EE7B7)
                  : (canAfford ? Colors.black87 : const Color(0xFF64748B)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: canAfford ? () => _buyUpgrade(upgradeId, nextCost) : null,
            child: Text(
              isMax ? 'MAX' : '🪙 $nextCost',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
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

    return Center(
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x660284C7), blurRadius: 20),
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
                      'CHARACTER SKINS WARDROBE',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
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

                      if (isUnlocked)
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            ),
          ],
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
