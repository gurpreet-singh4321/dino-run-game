import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;
import 'skin.dart';

class RiveDinoSkin extends CharacterSkin {
  @override
  String get id => 'rive_dino';

  @override
  String get displayName => 'Rive Dino';

  @override
  int get price => 0;

  @override
  Color get primaryColor => const Color(0xFF66BB6A);

  RiveComponent? _riveComponent;
  StateMachine? _stateMachine;
  rive.Animation? _animation;
  
  BooleanInput? _isJumping;
  BooleanInput? _isRunning;
  
  bool _isLoaded = false;
  
  static rive.File? _cachedRiveFile;

  static Future<void> preload() async {
    try {
      _cachedRiveFile = await rive.File.asset(
        'assets/dino.riv',
        riveFactory: rive.Factory.flutter,
      );
    } catch (_) {}
  }

  void load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final riveFile = _cachedRiveFile ?? await rive.File.asset(
        'assets/dino.riv',
        riveFactory: rive.Factory.flutter,
      );
      if (riveFile == null) return;
      final artboard = riveFile.defaultArtboard();
      if (artboard == null) return;
      
      _stateMachine = artboard.defaultStateMachine();
      
      if (_stateMachine == null && artboard.stateMachineCount() > 0) {
        _stateMachine = artboard.stateMachineAt(0);
      }
      
      if (_stateMachine == null && artboard.animationCount() > 0) {
        _animation = artboard.animationAt(0);
      }

      if (_stateMachine != null) {
        for (var input in _stateMachine!.inputs) {
          if (input is BooleanInput) {
            if (input.name.toLowerCase().contains('jump')) {
              _isJumping = input;
            } else if (input.name.toLowerCase().contains('run') || input.name.toLowerCase().contains('walk')) {
              _isRunning = input;
            }
          }
        }
      }

      _riveComponent = RiveComponent(
        artboard: artboard,
        stateMachine: _stateMachine,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      );
    } catch (_) {}
  }

  @override
  void update(double dt) {
    if (_stateMachine == null && _animation != null) {
      _animation!.advanceAndApply(dt);
    }
    _riveComponent?.update(dt);
  }

  void _syncState({bool isRunning = false, bool isJumping = false}) {
    if (_isRunning != null) _isRunning!.value = isRunning;
    if (_isJumping != null) _isJumping!.value = isJumping;
  }

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) {
    load();
    if (_riveComponent == null) return;
    
    _syncState(isRunning: true, isJumping: false);
    _riveComponent!.size = Vector2(size.width, size.height);
    canvas.save();
    canvas.translate(0, 15);
    _riveComponent!.render(canvas);
    canvas.restore();
  }

  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) {
    load();
    if (_riveComponent == null) return;
    
    _syncState(isRunning: false, isJumping: true);
    _riveComponent!.size = Vector2(size.width, size.height);
    canvas.save();
    canvas.translate(0, 15);
    _riveComponent!.render(canvas);
    canvas.restore();
  }

  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) {
    renderRunning(canvas, size, animFrame);
  }
}
