import 'dart:ui';

class CartSkin {
  final String id, name;
  final int price;
  final Color? tint;
  const CartSkin(this.id, this.name, this.price, [this.tint]);
}

class CartSkinCatalog {
  static const items = [
    CartSkin('fossil_rover', 'Fossil Rover', 0),
    CartSkin('lagoon_rover', 'Lagoon finish', 350, Color(0xFF8FE3DC)),
    CartSkin('sunset_rover', 'Sunset finish', 350, Color(0xFFFFB0A0)),
  ];
  static CartSkin? find(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static ColorFilter? filter(String id) {
    final tint = find(id)?.tint;
    return tint == null ? null : ColorFilter.mode(tint, BlendMode.modulate);
  }
}
