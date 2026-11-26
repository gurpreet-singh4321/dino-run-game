import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Feedback transforms only the artwork/content, preserving every hit target.
Widget adventureButtonMotion(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final quiet = MediaQuery.disableAnimationsOf(context);
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final attentive =
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused);
  return MenuMotionCue(
    enabled: !quiet && !disabled,
    engaged: pressed || attentive,
    child: AnimatedScale(
      scale: quiet || disabled ? 1 : (pressed ? .94 : (attentive ? 1.035 : 1)),
      duration: quiet ? Duration.zero : const Duration(milliseconds: 150),
      curve: pressed ? Curves.easeOut : Curves.easeOutBack,
      child: AnimatedSlide(
        offset: quiet || disabled ? Offset.zero : Offset(0, pressed ? .048 : 0),
        duration: quiet ? Duration.zero : const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: child,
      ),
    ),
  );
}

/// One brief flourish on arrival; no perpetual tickers across shop lists.
class MenuArrival extends StatelessWidget {
  final Widget child;
  final bool icon;
  final double direction;
  const MenuArrival({
    super.key,
    required this.child,
    this.icon = false,
    this.direction = 1,
  });
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: icon ? 900 : 260),
      child: child,
      builder: (context, t, child) {
        if (icon) {
          final wave = math.sin(t * math.pi * 3) * (1 - t);
          return Transform.translate(
            offset: Offset(0, -3 * math.sin(t * math.pi)),
            child: Transform.rotate(
              angle: wave * .15 * direction,
              child: child,
            ),
          );
        }
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - eased)),
            child: Transform.scale(scale: .97 + .03 * eased, child: child),
          ),
        );
      },
    );
  }
}

class MenuMotionCue extends InheritedWidget {
  final bool enabled, engaged;
  const MenuMotionCue({
    super.key,
    required this.enabled,
    required this.engaged,
    required super.child,
  });
  static MenuMotionCue? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuMotionCue>();
  @override
  bool updateShouldNotify(MenuMotionCue old) =>
      enabled != old.enabled || engaged != old.engaged;
}

/// Shop rows use the same state feedback as standard buttons.
class MenuInkAction extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  const MenuInkAction({
    super.key,
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });
  @override
  State<MenuInkAction> createState() => _MenuInkActionState();
}

class _MenuInkActionState extends State<MenuInkAction> {
  final states = WidgetStatesController();
  @override
  void dispose() {
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: widget.onTap,
    borderRadius: widget.borderRadius,
    statesController: states,
    child: ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: states,
      child: widget.child,
      builder: (context, value, child) => adventureButtonMotion(context, {
        ...value,
        if (widget.onTap == null) WidgetState.disabled,
      }, child),
    ),
  );
}
