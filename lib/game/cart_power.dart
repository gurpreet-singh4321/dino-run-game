enum CartPowerState { none, active, parked }

/// Cosmetic vehicle state; the existing player remains the only physics actor.
class CartPower {
  int charges = 0;
  bool parked = false;
  double dismountRemaining = 0;
  void collect({required bool park}) {
    charges = 3;
    parked = park;
    dismountRemaining = 0;
  }

  void spend() {
    if (charges <= 0) return;
    charges--;
    if (charges == 0) dismountRemaining = .35;
  }

  void update(double dt) {
    dismountRemaining = (dismountRemaining - dt).clamp(0.0, .35);
  }

  void clear() {
    charges = 0;
    parked = false;
    dismountRemaining = 0;
  }
}
