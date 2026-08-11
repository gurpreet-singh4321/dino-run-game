import 'package:flutter/material.dart';
import '../../managers/settings_manager.dart';

/// Interactive Settings Dialog overlay for Audio Volume & Phone Vibration preferences.
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.70),
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFFFFB300), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'SETTINGS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 26),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 30),

              // 1. Audio Volume Control
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _volume == 0 ? Icons.volume_off : Icons.volume_up,
                            color: const Color(0xFF00E5FF),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Audio Volume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(_volume * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF00E5FF),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: const Color(0xFFFFB300),
                      overlayColor: const Color(0xFFFFB300).withValues(alpha: 0.2),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (val) {
                        setState(() {
                          _volume = val;
                        });
                        SettingsManager.setVolume(val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Phone Vibration Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _vibrationEnabled ? Icons.vibration : Icons.mobile_off,
                          color: _vibrationEnabled ? const Color(0xFF00E676) : Colors.white38,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Vibration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Haptic feedback on phones',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _vibrationEnabled,
                      activeThumbColor: const Color(0xFF00E676),
                      activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white12,
                      onChanged: (val) {
                        setState(() {
                          _vibrationEnabled = val;
                        });
                        SettingsManager.setVibrationEnabled(val);
                        if (val) {
                          SettingsManager.triggerVibration(duration: 50);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: widget.onClose,
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
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
