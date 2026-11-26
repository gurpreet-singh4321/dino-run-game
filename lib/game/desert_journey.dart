import '../components/collectible.dart';
import '../components/obstacle.dart';

enum DesertBeatKind { pickup, obstacle, gap }

class DesertBeat {
  final double distance, height, width;
  final DesertBeatKind kind;
  final CollectibleType? pickup;
  final ObstacleType? obstacle;
  const DesertBeat.pickup(this.distance, this.height, this.pickup)
    : kind = DesertBeatKind.pickup,
      width = 42,
      obstacle = null;
  const DesertBeat.rock(this.distance, {this.obstacle = ObstacleType.rock})
    : kind = DesertBeatKind.obstacle,
      height = 48,
      width = 58,
      pickup = null;
  const DesertBeat.hanging(this.distance)
    : kind = DesertBeatKind.obstacle,
      height = 160,
      width = 65,
      pickup = null,
      obstacle = ObstacleType.ceilingPipe;
  const DesertBeat.gap(this.distance)
    : kind = DesertBeatKind.gap,
      height = 0,
      width = 130,
      pickup = null,
      obstacle = null;
}

/// Absolute route coordinates; only nearby beats are mounted in the world.
class DesertJourney {
  static const length = 15000.0;
  static const speed = 200.0;
  static final List<DesertBeat> beats = _build();
  static List<DesertBeat> _build() {
    final result = <DesertBeat>[];
    void trail(double center, {bool arc = false}) {
      for (var i = 0; i < 7; i++) {
        final lift = arc
            ? [55.0, 90.0, 125.0, 145.0, 125.0, 90.0, 55.0][i]
            : 50.0;
        result.add(
          DesertBeat.pickup(center - 180 + i * 60, lift, CollectibleType.coin),
        );
      }
    }

    trail(650);
    for (final x in [1400.0, 2300.0]) {
      result.add(DesertBeat.rock(x));
      trail(x, arc: true);
    }
    result.add(const DesertBeat.gap(3400));
    trail(3460, arc: true);
    result.add(const DesertBeat.pickup(4600, 50, CollectibleType.giant));
    for (final x in [5100.0, 5500.0, 5900.0]) {
      result.add(
        DesertBeat.rock(
          x,
          obstacle: x == 5500 ? ObstacleType.pillar : ObstacleType.rock,
        ),
      );
      trail(x);
    }
    trail(7200);
    result.add(const DesertBeat.hanging(7300));
    result.add(const DesertBeat.pickup(8000, 50, CollectibleType.cart));
    for (final x in [8500.0, 9000.0, 9500.0]) {
      result.add(DesertBeat.rock(x));
    }
    result.add(const DesertBeat.rock(10400));
    trail(10400, arc: true);
    result.add(const DesertBeat.gap(11900));
    trail(11960, arc: true);
    result.add(
      const DesertBeat.rock(13200, obstacle: ObstacleType.cactusSmall),
    );
    trail(13200, arc: true);
    trail(14100);
    result.sort((a, b) => a.distance.compareTo(b.distance));
    return List.unmodifiable(result);
  }

  bool active = false, completed = false;
  int nextBeat = 0;
  void start() {
    active = true;
    completed = false;
    nextBeat = 0;
  }

  void reset() {
    active = false;
    completed = false;
    nextBeat = 0;
  }

  String instruction(double distance) {
    if (distance < 900) return 'Follow the coins';
    if (distance < 2800) return 'Tap to jump';
    if (distance < 4000) return 'Tap twice over the fissure';
    if (distance < 6500) return 'Giant Dino smashes rocks';
    if (distance < 7700) return 'Stay low under the arch';
    if (distance < 9800) return 'Cart: three safe smashes';
    if (distance < 11000) return 'Cart empty? Jump!';
    if (distance < 12500) return 'Tap twice across the gap';
    if (distance < 13700) return 'One last jump';
    return 'The finish is close!';
  }
}
