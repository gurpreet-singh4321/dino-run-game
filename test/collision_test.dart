// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

class TestGame extends FlameGame with HasCollisionDetection {}

class TestBox extends PositionComponent with CollisionCallbacks {
  bool collided = false;
  final String name;

  TestBox(this.name, Vector2 pos, Vector2 sz) {
    position = pos;
    size = sz;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    collided = true;
    print('>>> TestBox $name hit ${other.runtimeType}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Minimal Flame collision test', () async {
    final game = TestGame();
    await game.onLoad();
    game.onMount();

    final b1 = TestBox('Box1', Vector2(100, 100), Vector2(50, 50));
    final b2 = TestBox('Box2', Vector2(120, 100), Vector2(50, 50));

    await game.add(b1);
    await game.add(b2);
    game.updateTree(0.016);

    print('b1.isMounted = ${b1.isMounted}');
    print('b1.children count = ${b1.children.length}');
    if (b1.children.isNotEmpty) {
      final hb = b1.children.first as ShapeHitbox;
      print('hb.isMounted = ${hb.isMounted}');
      print('hb parent = ${hb.parent}');
      print('hb ancestors = ${hb.ancestors().map((c) => c.runtimeType).toList()}');
      print('hb findParent HasCollisionDetection = ${hb.findParent<HasCollisionDetection>()}');
    }
    print('game.collisionDetection.items count = ${game.collisionDetection.items.length}');

    game.updateTree(0.016);

    print('b1.collided = ${b1.collided}');
    print('b2.collided = ${b2.collided}');
  });
}
