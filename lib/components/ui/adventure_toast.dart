import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';

void showAdventureToast(
  BuildContext context,
  String message, {
  double bottom = 12,
}) {
  final frame = Scaffold.of(context).context.findRenderObject();
  final width = frame is RenderBox && frame.hasSize
      ? frame.size.width
      : MediaQuery.sizeOf(context).width;
  final inset = math.max(16.0, (width - 480) / 2);
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(inset, 0, inset, bottom),
      padding: EdgeInsets.zero,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 3),
      content: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(color: Color(0x66090E16), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: CustomPaint(
              painter: const PlaqueBadgePainter(
                top: Color(0xFF2D415D),
                mid: Color(0xFF1D2C42),
                bottom: Color(0xFF121C2B),
                outline: Color(0xFF0C111A),
                lip: Color(0xFF0A1018),
                innerRim: Color(0xDDD8AE5C),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF2BC), MenuPalette.gold, Color(0xFFE09F24)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6B4512), width: 1.5),
                        boxShadow: const [BoxShadow(color: Color(0x660C121B), offset: Offset(0, 1.5))],
                      ),
                      child: const MenuCheckmark(
                        size: 15,
                        color: MenuPalette.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          shadows: [Shadow(color: Color(0x990A1018), offset: Offset(0, 1.5), blurRadius: 2)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Dismiss notification',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: messenger.hideCurrentSnackBar,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CustomPaint(
                                  painter: const PlaqueBadgePainter(
                                    top: Color(0xFFDC5458),
                                    mid: MenuPalette.red,
                                    bottom: Color(0xFF9C292E),
                                    outline: Color(0xFF471417),
                                    lip: Color(0xFF631C20),
                                    innerRim: Color(0x88FFE0A8),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Center(
                                      child: MenuIllustration(MenuSymbol.close, size: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
