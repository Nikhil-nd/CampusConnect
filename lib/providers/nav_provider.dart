import 'package:flutter/foundation.dart';

/// Owns the bottom-navigation index for the app shell.
class NavProvider extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int value) {
    _index = value;
    notifyListeners();
  }
}
