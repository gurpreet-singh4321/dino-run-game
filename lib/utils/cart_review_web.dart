import 'dart:js_interop';

@JS('window.location.search')
external JSString get _search;

bool get cartReviewRequested {
  if (const bool.fromEnvironment('CART_REVIEW')) return true;
  final query = _search.toDart;
  return query.startsWith('?') &&
      Uri.splitQueryString(query.substring(1))['cart'] == '1';
}
