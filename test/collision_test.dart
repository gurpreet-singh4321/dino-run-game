// Headless Flame mount bypasses GameWidget intentionally.
// ignore_for_file: invalid_use_of_internal_member
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

class TestGame extends FlameGame with HasCollisionDetection {}
class TestBox extends PositionComponent with CollisionCallbacks {
  bool collided = false;
  TestBox(Vector2 pos) : super(position: pos, size: Vector2.all(50));
  @override
  Future<void> onLoad() async { await add(RectangleHitbox(isSolid: true)); }
  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other); collided = true;
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Mounted Flame hitboxes collide only when overlapping', () async {
    final game = TestGame()..onGameResize(Vector2(640, 360));
    await game.load(); game.mount();
    final first = TestBox(Vector2(100, 100));
    final second = TestBox(Vector2(120, 100));
    final distant = TestBox(Vector2(300, 100));
    await game.addAll([first, second, distant]); await game.ready();
    game.update(.016);
    expect(first.collided, isTrue); expect(second.collided, isTrue);
    expect(distant.collided, isFalse);
    expect(game.collisionDetection.items, hasLength(3));
  });
}
