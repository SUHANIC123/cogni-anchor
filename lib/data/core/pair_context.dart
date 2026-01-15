class PairContext {
  static String? pairId;

  static void set(String id) {
    pairId = id;
  }

  static String get require {
    if (pairId == null) {
      throw Exception("Pair ID not initialized");
    }
    return pairId!;
  }

  static void clear() {
    pairId = null;
  }
}
