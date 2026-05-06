import 'package:flutter/foundation.dart';

/// Owns feed-specific UI state such as search text and marketplace sort order.
class FeedProvider extends ChangeNotifier {
  String _searchQuery = '';
  bool _priceLowToHigh = true;

  String get searchQuery => _searchQuery;
  bool get priceLowToHigh => _priceLowToHigh;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void togglePriceSort() {
    _priceLowToHigh = !_priceLowToHigh;
    notifyListeners();
  }
}
