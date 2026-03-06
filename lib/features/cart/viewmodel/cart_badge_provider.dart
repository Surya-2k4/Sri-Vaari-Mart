import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_viewmodel.dart';

final cartItemCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartViewModelProvider);

  return cartState.when(
    loading: () => 0,
    error: (_, __) => 0,
    data: (items) {
      return items.fold(0, (sum, item) => sum + item.quantity);
    },
  );
});
