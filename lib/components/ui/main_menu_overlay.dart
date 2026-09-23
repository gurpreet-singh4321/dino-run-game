import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/dino_game.dart';
import '../../skins/skin_registry.dart';
import '../../skins/skin.dart';
import 'adventure_panels.dart';
import '../../managers/audio_manager.dart';
import '../../game/game_state.dart';

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
  final ScrollController _epochScroll = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _runnerAnimController;
  late Animation<double> _pulseAnimation;
  final FocusNode _focusNode = FocusNode();

  int _selectedRealmIndex = 0;
  int _selectedSkinIndex = 0;
  int _mobileTab = 0;

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
    final allSkins = SkinRegistry.playable;
    final idx = allSkins.indexWhere((s) => s.id == currentSkinId);
    if (idx != -1) {
      _selectedSkinIndex = idx;
    }
  }

  @override
  void dispose() {
    _epochScroll.dispose();
    _pulseController.dispose();
    _runnerAnimController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onStartExpedition() {
    AudioManager.playJump();
    widget.game.overlays.remove('MainMenuOverlay');
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
    final allSkins = SkinRegistry.playable;
    setState(() {
      _selectedSkinIndex = (_selectedSkinIndex + 1) % allSkins.length;
      final newSkin = allSkins[_selectedSkinIndex];
      widget.game.player.setSkin(newSkin);
    });
    AudioManager.playButton();
  }

  void _prevSkin() {
    final allSkins = SkinRegistry.playable;
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
      builder: (ctx) => AdventureUpgrades(game: widget.game),
    ).then((_) => setState(() {}));
  }

  void _openSkins() {
    AudioManager.playButton();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AdventureWardrobe(game: widget.game),
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

  void _scrollEpochs(int direction) {
    if (!_epochScroll.hasClients) return;
    _epochScroll.animateTo((_epochScroll.offset + direction * 296).clamp(0.0, _epochScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  void _openEvents() {
    showDialog<void>(context: context, builder: (context) => AdventurePanel(
      title: 'Adventure journal', subtitle: 'Small challenges. Happy discoveries.',
      child: AnimatedBuilder(animation: _runnerAnimController, builder: (context, child) =>
        _buildRightPanel(widget.game.coinManager.coins, widget.game.coinManager.highScore)),
    ));
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
        backgroundColor: const Color(0xFF244A59),
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
    if (widget.game.state != GameState.menu) {
      return const SizedBox.shrink();
    }

    final coinManager = widget.game.coinManager;
    final coins = coinManager.coins;
    final hiScore = coinManager.highScore;
    final allSkins = SkinRegistry.playable;
    final currentSkin = allSkins.isNotEmpty ? allSkins[_selectedSkinIndex] : SkinRegistry.defaultSkin;
    final size = MediaQuery.of(context).size;
    final isMobile = size.height < 520 || size.width < 800;

    if (size.width > 0) {
      return _landscapeHome(currentSkin, coins, hiScore);
    }

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
                  _buildTopBar(coins, isMobile: isMobile),

                  // 2. Main Body (Mobile 2-column or Desktop 3-column)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                      child: isMobile
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Mobile Left Column (Tabs: Epochs / Missions)
                                SizedBox(
                                  width: size.width > 700 ? 310 : 260,
                                  child: _buildMobileLeftColumn(coins, hiScore),
                                ),
                                const SizedBox(width: 12),
                                // Mobile Right Column (Runner Showcase & Play Action)
                                Expanded(
                                  child: _buildCenterStage(currentSkin, isMobile: true),
                                ),
                              ],
                            )
                          : Row(
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
                                  child: _buildCenterStage(currentSkin, isMobile: false),
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
                  _buildFooter(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _landscapeHome(CharacterSkin skin, int coins, int best) {
    Widget action(IconData icon, String label, VoidCallback tap) => FilledButton.tonalIcon(
      onPressed: tap, icon: Icon(icon, size: 18), label: Text(label),
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)));
    const art = ['desert_fossil_canyon.png', 'rain_painted_v1.png', 'forest_painted_v1.png', 'ice_painted_v1.png', 'cosmos_painted_v1.png', 'volcano_painted_v1.png'];
    return Material(color: Colors.transparent, child: DecoratedBox(
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0x44152C40), Color(0xDD152C40)],
        begin: Alignment.centerLeft, end: Alignment.centerRight)),
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/app_icon.png', width: 36, height: 36)),
            const SizedBox(width: 10),
            const Expanded(child: Text('DINO RUN  ·  EPOCHS', style: TextStyle(color: Color(0xFFFFE5A3), fontWeight: FontWeight.w900, fontSize: 16))),
            Chip(avatar: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFCF62)), label: Text('$coins')),
            IconButton(tooltip: 'Settings', onPressed: _openSettings, icon: const Icon(Icons.settings_rounded, color: Colors.white)),
          ])),
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(children: [
            Expanded(flex: 4, child: Column(children: [
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                final height = math.min(constraints.maxHeight, 300.0);
                return Stack(alignment: Alignment.center, children: [
                  Container(decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0x66FFCF62), Colors.transparent]))),
                  SizedBox(width: height * .83, height: height,
                    child: _SkinPreviewWidget(skin: skin, ticker: _runnerAnimController)),
                ]);
              })),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                Expanded(child: Text(skin.displayName, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),

              ]),
            ])),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 6, runSpacing: 6, children: [
                  action(Icons.checkroom_rounded, 'Wardrobe', _openSkins),
                  action(Icons.auto_awesome_rounded, 'Upgrades', _openUpgrades),
                  action(Icons.auto_stories_rounded, 'Journal', _openEvents),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Text('PICK AN EPOCH', style: TextStyle(color: Color(0xFFFFE5A3), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
                  IconButton(tooltip: 'Earlier epochs', onPressed: () => _scrollEpochs(-1), icon: const Icon(Icons.chevron_left_rounded)),
                  IconButton(tooltip: 'More epochs', onPressed: () => _scrollEpochs(1), icon: const Icon(Icons.chevron_right_rounded)),
                ]),
                const SizedBox(height: 8),
                SizedBox(height: 90, child: ListView.separated(controller: _epochScroll, scrollDirection: Axis.horizontal,
                  itemCount: _realms.length, separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedRealmIndex;
                    return Semantics(
                      selected: selected,
                      button: true,
                      label: _realms[index]['name'] as String,
                      child: InkWell(onTap: () => _selectRealm(index),
                      borderRadius: BorderRadius.circular(16), child: Container(width: 140,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: selected ? const Color(0xFFFFCF62) : Colors.white24, width: selected ? 3 : 1),
                          image: DecorationImage(image: AssetImage('assets/images/biomes/${art[index]}'), fit: BoxFit.cover)),
                        child: Container(alignment: Alignment.bottomLeft, padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xEE102334)])),
                          child: Text('${selected ? "✓ " : ""}${_realms[index]['name']}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                      )));
                  })),
                const SizedBox(height: 12),
                _buildDailySupplyCard(),
                const SizedBox(height: 12),

              ]))),
              const SizedBox(height: 8),
              SizedBox(height: 50, child: FilledButton.icon(onPressed: _onStartExpedition,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text('PLAY · ${_realms[_selectedRealmIndex]['name']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFCF62), foregroundColor: const Color(0xFF413020), textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)))),
            ])),
          ]))),
      ])),
    ));
  }

  // -------------------------------------------------------------
  // TOP BAR
  // -------------------------------------------------------------
  Widget _buildTopBar(int coins, {required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 20.0, vertical: isMobile ? 4.0 : 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            children: [
              SizedBox(
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
                          color: const Color(0xFFFFCF62),
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
                  color: const Color(0xFF244A59).withValues(alpha: 0.85),
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
              Semantics(
                button: true,
                label: 'Upgrades',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openUpgrades,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF244A59).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF475569), width: 1),
                      ),
                      child: const Icon(Icons.bolt, color: Color(0xFFCBD5E1), size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Skins Button
              Semantics(
                button: true,
                label: 'Skins',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openSkins,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF244A59).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF475569), width: 1),
                      ),
                      child: const Icon(Icons.checkroom, color: Color(0xFFCBD5E1), size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Codex Button
              Semantics(
                button: true,
                label: 'Time Codex',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openTimeCodex,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF244A59).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF475569), width: 1),
                      ),
                      child: const Icon(Icons.menu_book, color: Color(0xFFCBD5E1), size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Tutorial Button
              Semantics(
                button: true,
                label: 'Tutorial',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openTutorial,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF244A59).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF475569), width: 1),
                      ),
                      child: const Icon(Icons.help_outline, color: Color(0xFFCBD5E1), size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Settings Gear Icon
              Semantics(
                button: true,
                label: 'Settings',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openSettings,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF244A59).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF475569), width: 1),
                      ),
                      child: const Icon(Icons.settings, color: Color(0xFFCBD5E1), size: 16),
                    ),
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
  // LEFT PANEL (Expeditions, Daily Supply & Realm Selector)
  // -------------------------------------------------------------
  Widget _buildDailySupplyCard() {
    final canClaimDaily = widget.game.coinManager.canClaimDailyReward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 13),
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
                    fontSize: 9.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '+150 Coins',
                  style: TextStyle(
                    color: Color(0xFFBAE6FD),
                    fontSize: 8.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: canClaimDaily ? 'Claim Daily Supply Drop' : 'Daily Supply Drop Claimed',
            child: MouseRegion(
              cursor: canClaimDaily ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canClaimDaily ? _claimDailyReward : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpochList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _realms.length,
      itemBuilder: (context, index) {
        final realm = _realms[index];
        final isSelected = _selectedRealmIndex == index;
        final color = realm['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectRealm(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.22)
                      : const Color(0xFF183848).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF334155).withValues(alpha: 0.7),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(realm['icon'] as IconData, color: color, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  realm['name'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (realm['badge'] != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    realm['badge'] as String,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 7.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            realm['bonus'] as String,
                            style: TextStyle(
                              color: isSelected ? color : const Color(0xFF94A3B8),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: color, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDailySupplyCard(),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF183848).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Row(
            children: [
              Icon(Icons.public, color: Color(0xFF38BDF8), size: 13),
              SizedBox(width: 6),
              Text(
                'STARTING EPOCH',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _buildEpochList(),
        ),
      ],
    );
  }

  Widget _buildMobileLeftColumn(int coins, int hiScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab switcher (Epochs / Missions)
        Container(
          height: 32,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF183848).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _mobileTab = 0);
                    AudioManager.playButton();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _mobileTab == 0 ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public,
                          size: 12,
                          color: _mobileTab == 0 ? Colors.black87 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'EPOCHS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: _mobileTab == 0 ? Colors.black87 : const Color(0xFF94A3B8),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _mobileTab = 1);
                    AudioManager.playButton();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _mobileTab == 1 ? const Color(0xFF0284C7) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.military_tech,
                          size: 12,
                          color: _mobileTab == 1 ? Colors.white : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MISSIONS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: _mobileTab == 1 ? Colors.white : const Color(0xFF94A3B8),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _mobileTab == 0
              ? _buildEpochList()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDailySupplyCard(),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 220,
                        child: _buildRightPanel(coins, hiScore),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // CENTER STAGE (Runner Preview & Start Action)
  // -------------------------------------------------------------
  Widget _buildCenterStage(CharacterSkin currentSkin, {required bool isMobile}) {
    final skinName = currentSkin.displayName.toUpperCase();
    final isUnlocked = widget.game.coinManager.isSkinUnlocked(currentSkin.id);
    final selectedRealm = _realms[_selectedRealmIndex];
    final selectedRealmColor = selectedRealm['color'] as Color;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Banner: Active Epoch Selector Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _selectRealm((_selectedRealmIndex + 1) % _realms.length);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selectedRealmColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selectedRealmColor, width: 1.5),
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
                      Icon(selectedRealm['icon'] as IconData, color: selectedRealmColor, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'EPOCH: ${(selectedRealm['name'] as String).toUpperCase()} ❯',
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
              ),
            ),
          ],
        ),

        // Character Showcase Stage with Skin Switcher Arrows
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Previous Skin Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 18),
                      tooltip: 'Previous Skin',
                      onPressed: _prevSkin,
                    ),
                    const SizedBox(width: 6),

                    // Pedestal Platform & Live Animated Character
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 1. Aura Effect
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: const Offset(0, -10),
                              child: Container(
                                width: (isMobile ? 110 : 140) + _pulseAnimation.value * 15,
                                height: isMobile ? 180 : 250,
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
                                      blurRadius: 35 + _pulseAnimation.value * 15,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 2. Rotating Platform Ring
                        AnimatedBuilder(
                          animation: _runnerAnimController,
                          builder: (context, child) {
                            final ringSize = isMobile ? 120.0 : 160.0;
                            return Transform.translate(
                              offset: Offset(0, isMobile ? 32 : 42),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.002)
                                  ..rotateX(1.3)
                                  ..rotateZ(_runnerAnimController.value * math.pi * 2),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: ringSize,
                                      height: ringSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: currentSkin.primaryColor,
                                          width: isMobile ? 5.0 : 7.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: currentSkin.primaryColor,
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ringSize,
                                      height: ringSize,
                                      child: CircularProgressIndicator(
                                        value: 0.85,
                                        strokeWidth: isMobile ? 7 : 9,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 3. Platform Glow Core
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, isMobile ? 32 : 42),
                              child: Container(
                                width: (isMobile ? 100 : 135) + _pulseAnimation.value * 15,
                                height: (isMobile ? 26 : 35) + _pulseAnimation.value * 8,
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
                                      blurRadius: 40,
                                      spreadRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Animated Dinosaur Preview on Pedestal
                        Transform.translate(
                          offset: Offset(0, isMobile ? -10 : -15),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _triggerDinoRoarEasterEgg,
                              child: Tooltip(
                                message: 'Tap Dino for a surprise!',
                                child: SizedBox(
                                  width: isMobile ? 65 : 80,
                                  height: isMobile ? 78 : 96,
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

                    const SizedBox(width: 6),
                    // Next Skin Button
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                      tooltip: 'Next Skin',
                      onPressed: _nextSkin,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Character Stats & Badges
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Runner Name Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF183848).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: currentSkin.primaryColor, width: 1.2),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge (EQUIPPED / LOCKED)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isUnlocked ? const Color(0xFF065F46) : const Color(0xFF78350F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isUnlocked) ...[
                            const Icon(Icons.monetization_on, color: Color(0xFFFDE68A), size: 11),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isUnlocked ? 'EQUIPPED' : '${currentSkin.price} TO UNLOCK',
                            style: TextStyle(
                              color: isUnlocked ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
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
        ),

        // Action Section (PROMINENT START EXPEDITION BUTTON)
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onStartExpedition,
                  child: Container(
                    width: isMobile ? 290 : 340,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          selectedRealmColor,
                          const Color(0xFFEA580C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFFFFFFF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedRealmColor.withValues(alpha: 0.5 + _pulseAnimation.value * 0.3),
                          blurRadius: 14 + _pulseAnimation.value * 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          'PLAY: ${(selectedRealm['name'] as String).toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (!isMobile) ...[
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
            color: const Color(0xFF183848).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 6,
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
        color: const Color(0xFF183848).withValues(alpha: 0.8),
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
                          ? const Color(0xFF244A59)
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
                    backgroundColor: const Color(0xFF244A59),
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
  Widget _buildFooter(bool isMobile) {
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
    skin.renderCharacter(canvas, size, frame);
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) {
    return true; // Repaint continuous rig animation and cosmetic changes.
  }
}

// -----------------------------------------------------------------
// DIALOGS: UPGRADES, SKINS, TIME CODEX, TUTORIAL
// -----------------------------------------------------------------

class _TimeCodexDialog extends StatelessWidget {
  const _TimeCodexDialog();
  @override
  Widget build(BuildContext context) => AdventurePanel(title: 'A world of adventures', subtitle: 'Six epochs to explore with Dino.',
    child: ListView(children: const [
      Text('Ancient Desert · Jurassic Monsoon · Primeval Forest\n\nGlacial Tundra · Cosmic Orbit · Volcano Inferno',
        style: TextStyle(color: Color(0xFF173B48), fontSize: 18, height: 1.6)),
    ]));
}
class _TutorialDialog extends StatelessWidget {
  const _TutorialDialog();
  @override
  Widget build(BuildContext context) => AdventurePanel(title: 'Let’s go exploring!', subtitle: 'Small feet. Big adventures.',
    child: ListView(children: const [
      Text('Tap to jump. Tap again for a double jump.\n\nCollect coins to dress up Dino and improve your boosts.\n\nGrab a shield for protection, a magnet for coins, or a rocket for a trip to space.\n\nTap pause whenever you need a break.',
        style: TextStyle(color: Color(0xFF173B48), fontSize: 17, height: 1.6)),
    ]));
}
