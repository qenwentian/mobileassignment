import 'package:flutter/foundation.dart';
import '../models/item_model.dart';

/// Bottom-nav state + the map's selected pin. Kept in a ViewModel so
/// Feed -> Details -> Map (and Report -> Feed) never touch widget state.
class NavViewModel extends ChangeNotifier {
  int _index = 0;
  String? _selectedPinId;
  bool _routeVisible = false;

  int get index => _index;
  String? get selectedPinId => _selectedPinId;
  bool get routeVisible => _routeVisible;

  void setIndex(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }

  /// "Directions" on Item Details: open Map with that building pre-highlighted.
  void focusItemOnMap(ItemModel item) {
    _selectedPinId = item.buildingId;
    _routeVisible = true;
    _index = 2;
    notifyListeners();
  }

  void selectPin(String id) {
    _selectedPinId = id;
    _routeVisible = false;
    notifyListeners();
  }

  void showRoute() {
    _routeVisible = true;
    notifyListeners();
  }

  void reset() {
    _index = 0;
    _selectedPinId = null;
    _routeVisible = false;
    notifyListeners();
  }
}
