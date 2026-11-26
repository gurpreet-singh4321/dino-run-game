import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

enum HazardMaterial { stone, wood, ice, crystal, plant, metal, feathers, fire }

enum ContactOutcome { ignored, damage, shielded, giantSmash, cartSmash }

/// Identity and an atomic one-contact latch live on the hazard, not the player.
/// Child hitboxes resolve to this owner so one pipe/rock never rewards twice.
mixin HazardContact on PositionComponent {
  bool _impactClaimed = false;
  HazardMaterial get impactMaterial;
  bool get impactReady => true;
  bool get impactClaimed => _impactClaimed;
  PositionComponent get contactOwner => this;

  bool claimImpact() {
    if (_impactClaimed || !impactReady || isRemoving || isRemoved) return false;
    _impactClaimed = true;
    void deactivate(Component component) {
      for (final child in component.children) {
        if (child is ShapeHitbox) child.collisionType = CollisionType.inactive;
        deactivate(child);
      }
    }

    deactivate(this);
    return true;
  }
}

class HazardContactResolver {
  static HazardContact? ownerOf(Component component) {
    Component? current = component;
    while (current != null) {
      if (current is HazardContact) return current;
      current = current.parent;
    }
    return null;
  }

  static ContactOutcome resolve(
    HazardContact hazard, {
    required bool giant,
    bool cart = false,
    required bool recovering,
    required bool shielded,
  }) {
    // Giant still crushes during pickup/previous damage protection.
    if (!giant && !cart && recovering) return ContactOutcome.ignored;
    if (!hazard.claimImpact()) return ContactOutcome.ignored;
    if (giant) return ContactOutcome.giantSmash;
    if (cart) return ContactOutcome.cartSmash;
    return shielded ? ContactOutcome.shielded : ContactOutcome.damage;
  }
}
