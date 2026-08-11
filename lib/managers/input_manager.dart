import '../game/dino_game.dart';
import 'package:flame/components.dart';

class InputManager extends Component with HasGameReference<DinoGame> {
  double pointerX = 0;
  bool isDragging = false;
}
