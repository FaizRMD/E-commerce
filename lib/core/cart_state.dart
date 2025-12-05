import 'package:flutter/foundation.dart';

/// State global sederhana untuk menyimpan jumlah item di keranjang.
class CartState {
  static final ValueNotifier<int> itemCount = ValueNotifier<int>(0);

  static void add(int count) {
    itemCount.value += count;
  }

  static void clear() {
    itemCount.value = 0;
  }
}
