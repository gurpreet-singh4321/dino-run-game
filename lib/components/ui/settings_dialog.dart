import 'package:flutter/material.dart';
import '../../managers/settings_manager.dart';
import 'adventure_panels.dart';
class SettingsDialog extends StatefulWidget {
  final VoidCallback onClose;
  const SettingsDialog({super.key, required this.onClose});
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}
class _SettingsDialogState extends State<SettingsDialog> {
  double _volume = SettingsManager.volume;
  bool _vibrationEnabled = SettingsManager.vibrationEnabled;
  @override
  Widget build(BuildContext context) => AdventurePanel(title: 'Make it yours', subtitle: 'A comfy adventure, just the way you like it.', onClose: widget.onClose,
    child: Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DEEEA), brightness: Brightness.dark)),
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
        const SizedBox(height: 8),
        Text('Sound volume · ${(_volume * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Slider(value: _volume, divisions: 20, label: '${(_volume * 100).round()}%',
          onChanged: (value) { setState(() => _volume = value); SettingsManager.setVolume(value); }),
        Material(color: Colors.transparent, child: SwitchListTile(contentPadding: EdgeInsets.zero,
          title: const Text('Little rumbles'), subtitle: const Text('Vibration feedback during play'),
          value: _vibrationEnabled, onChanged: (value) {
            setState(() => _vibrationEnabled = value);
            SettingsManager.setVibrationEnabled(value);
            if (value) SettingsManager.triggerVibration(duration: 50);
          })),
        const SizedBox(height: 12),
        FilledButton(onPressed: widget.onClose, child: const Text('All set!')),
      ])));
}
