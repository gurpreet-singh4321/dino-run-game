import 'package:flutter/material.dart';
import '../../managers/audio_manager.dart';
import '../../managers/settings_manager.dart';
import 'adventure_panels.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onClose;
  final int stage;
  const SettingsDialog({super.key, required this.onClose, this.stage = 0});
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  double volume = SettingsManager.volume;
  bool vibration = SettingsManager.vibrationEnabled;
  bool reduceMotion = SettingsManager.reduceMotion;
  bool saving = false;
  bool? saved;
  int _request = 0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save(Future<bool> change) async {
    final request = ++_request;
    setState(() {
      saving = true;
      saved = null;
    });
    final result = await change;
    if (!mounted || request != _request) return;
    setState(() {
      saving = false;
      saved = result;
    });
  }

  @override
  Widget build(BuildContext context) => AdventurePanel(
    title: 'Settings',
    accent: MenuPalette.terracotta,
    maxWidth: 640,
    maxHeight: MediaQuery.orientationOf(context) == Orientation.portrait
        ? 560
        : 455,
    subtitle: 'Your adventure, your way.',
    stage: widget.stage,
    onClose: widget.onClose,
    child: Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(left: 2, right: 10, top: 2, bottom: 4),
              children: [
                _SettingsCard(
                  child: Column(
                    children: [
                      _PreferenceToggle(
                        key: const ValueKey('sound-setting'),
                        kind: volume > 0
                            ? _SettingIcon.soundOn
                            : _SettingIcon.soundOff,
                        title: 'Sound',
                        description: volume > 0
                            ? 'Music and adventure sounds'
                            : 'Muted — enjoy a quiet adventure',
                        value: volume > 0,
                        onChanged: (enabled) {
                          final change = SettingsManager.setSoundEnabled(enabled);
                          setState(() => volume = SettingsManager.volume);
                          _save(change);
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE0C2),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFCBB082), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                key: const ValueKey('volume-setting'),
                                value: volume,
                                divisions: 20,
                                label: '${(volume * 100).round()}%',
                                semanticFormatterCallback: (value) =>
                                    '${(value * 100).round()} percent sound volume',
                                onChanged: (value) {
                                  setState(() => volume = value);
                                  _save(SettingsManager.setVolume(value));
                                },
                                onChangeEnd: (value) {
                                  if (value > 0) {
                                    AudioManager.ensureAudioPlaying();
                                  }
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBB082), width: 1),
                              ),
                              child: Text(
                                volume > 0 ? '${(volume * 100).round()}%' : 'Muted',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: MenuPalette.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: _PreferenceToggle(
                    key: const ValueKey('vibration-setting'),
                    kind: _SettingIcon.vibration,
                    title: 'Vibration',
                    description: 'Gentle taps on supported devices',
                    value: vibration,
                    onChanged: (value) {
                      setState(() => vibration = value);
                      _save(SettingsManager.setVibrationEnabled(value));
                      if (value) SettingsManager.triggerVibration(duration: 35);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: _PreferenceToggle(
                    key: const ValueKey('motion-setting'),
                    kind: _SettingIcon.motion,
                    title: 'Reduced motion',
                    description: 'Calmer menus. Running and jumps stay the same.',
                    value: reduceMotion,
                    onChanged: (value) {
                      setState(() => reduceMotion = value);
                      _save(SettingsManager.setReduceMotion(value));
                    },
                  ),
                ),
                if (MediaQuery.disableAnimationsOf(context) && !reduceMotion)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 2),
                    child: Text(
                      'Your device already requests reduced motion.',
                      style: TextStyle(color: MenuPalette.muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFD5BE94), width: 1.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    saving
                        ? 'Saving…'
                        : saved == false
                        ? 'Applied here. Could not save.'
                        : saved == true
                        ? 'Changes saved'
                        : 'Changes save automatically',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: saved == false ? MenuPalette.red : MenuPalette.muted,
                    ),
                  ),
                ),
              ),
              if (saved == false)
                TextButton(
                  onPressed: () => _save(SettingsManager.save()),
                  child: const Text('Retry'),
                ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('settings-done'),
                style: adventureButtonStyle(const Color(0xFF136C51)),
                onPressed: widget.onClose,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFCF6), Color(0xFFF6EAD1)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFCEB589), width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0x26543E22), offset: Offset(0, 2.5))],
    ),
    child: child,
  );
}

enum _SettingIcon { soundOn, soundOff, vibration, motion }

class _PreferenceToggle extends StatelessWidget {
  final _SettingIcon kind;
  final String title, description;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PreferenceToggle({
    super.key,
    required this.kind,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => SwitchListTile(
    dense: true,
    minTileHeight: 64,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    secondary: Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFDFC0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBB082), width: 1.4),
      ),
      child: CustomPaint(painter: _SettingGlyphPainter(kind)),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 17.5,
        fontWeight: FontWeight.w700,
        color: MenuPalette.ink,
      ),
    ),
    subtitle: Text(
      description,
      style: const TextStyle(fontSize: 12.5, color: MenuPalette.muted),
    ),
    value: value,
    onChanged: onChanged,
  );
}

class _SettingGlyphPainter extends CustomPainter {
  final _SettingIcon kind;
  const _SettingGlyphPainter(this.kind);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final fill = Paint()..color = const Color(0xFFB54E24);
    final stroke = Paint()
      ..color = const Color(0xFF1F2A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case _SettingIcon.soundOn:
      case _SettingIcon.soundOff:
        final cone = Path()
          ..moveTo(4, 11)
          ..lineTo(9, 11)
          ..lineTo(15, 5.5)
          ..lineTo(15, 22.5)
          ..lineTo(9, 17)
          ..lineTo(4, 17)
          ..close();
        canvas.drawPath(cone, fill);
        canvas.drawPath(cone, stroke);
        if (kind == _SettingIcon.soundOn) {
          canvas.drawArc(
            const Rect.fromLTWH(13, 8, 9, 12),
            -0.85,
            1.7,
            false,
            stroke..color = const Color(0xFF136C51),
          );
          canvas.drawArc(
            const Rect.fromLTWH(15, 5, 11, 18),
            -0.8,
            1.6,
            false,
            stroke,
          );
        } else {
          stroke.color = const Color(0xFFC83F44);
          canvas.drawLine(const Offset(18, 10), const Offset(25, 18), stroke);
          canvas.drawLine(const Offset(25, 10), const Offset(18, 18), stroke);
        }
      case _SettingIcon.vibration:
        final phone = RRect.fromRectAndRadius(
          const Rect.fromLTWH(8.5, 4, 11, 20),
          const Radius.circular(2.8),
        );
        canvas.drawRRect(phone, fill..color = const Color(0xFF1F2A3A));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10.5, 6.5, 7, 14),
            const Radius.circular(1.2),
          ),
          fill..color = const Color(0xFFFFD877),
        );
        canvas.drawLine(const Offset(5, 8.5), const Offset(3, 12), stroke);
        canvas.drawLine(const Offset(3, 12), const Offset(5, 15.5), stroke);
        canvas.drawLine(const Offset(5, 15.5), const Offset(3, 19), stroke);
        canvas.drawLine(const Offset(23, 8.5), const Offset(25, 12), stroke);
        canvas.drawLine(const Offset(25, 12), const Offset(23, 15.5), stroke);
        canvas.drawLine(const Offset(23, 15.5), const Offset(25, 19), stroke);
      case _SettingIcon.motion:
        final leaf = Path()
          ..moveTo(14, 24)
          ..quadraticBezierTo(4, 18, 6, 7)
          ..quadraticBezierTo(16, 7, 14, 24)
          ..close();
        final right = Path()
          ..moveTo(14, 24)
          ..quadraticBezierTo(24, 18, 22, 7)
          ..quadraticBezierTo(12, 7, 14, 24)
          ..close();
        canvas.drawPath(leaf, fill..color = const Color(0xFF1A9264));
        canvas.drawPath(right, fill..color = const Color(0xFF47CE85));
        canvas.drawPath(leaf, stroke);
        canvas.drawPath(right, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SettingGlyphPainter old) => old.kind != kind;
}
