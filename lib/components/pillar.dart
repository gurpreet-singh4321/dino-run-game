import 'obstacle.dart';

/// Stone column / pipe obstacle component.
class Pillar extends Obstacle {
  Pillar({required super.speed}) : super(type: ObstacleType.pillar);
}
