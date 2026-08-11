import 'dart:math' as math;
import 'package:flame/components.dart';

class SpeedManager extends Component {
  static const double baseSpeed = 200;
  static const double maxAdd = 250;
  double currentSpeed = baseSpeed;

  void updateSpeed(double score) {
    final curve = 1 - math.exp(-score / 600);
    currentSpeed = baseSpeed + maxAdd * curve;
  }

  void reset() {
    currentSpeed = baseSpeed;
  }

  double get speedMultiplier => currentSpeed / baseSpeed;
}
