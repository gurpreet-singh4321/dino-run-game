/// A fixed real-time step, with time scaling applied once by the caller.
/// Long frames carry their remainder rather than changing physics or losing time.
class RunSimulation {
  static const step = 1 / 120;
  double _remainder = 0;
  double elapsed = 0;

  void advance(double dt, void Function(double) simulate) {
    if (!dt.isFinite || dt <= 0) return;
    _remainder += dt;
    var budget = 120;
    while (_remainder + 1e-10 >= step && budget-- > 0) {
      _remainder -= step;
      elapsed += step;
      simulate(step);
    }
  }

  void reset() { _remainder = 0; elapsed = 0; }
}
