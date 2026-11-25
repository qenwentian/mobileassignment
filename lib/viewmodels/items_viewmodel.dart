import 'package:flutter/foundation.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/item_service.dart';

class ItemsViewModel extends ChangeNotifier {
  ItemsViewModel(this._service) : _items = _service.seed();
  final ItemService _service;
  List<ItemModel> _items;

  String _query = '';
  String _category = 'All';

  static const filterCategories = ['All', 'Electronics', 'Wallets', 'Keys'];
  static const reportCategories = [
    'Electronics', 'Wallets', 'Keys', 'Books', 'IDs', 'Other'
  ];

  List<CampusPin> get pins => ItemService.pins;
  String get query => _query;
  String get category => _category;
  List<ItemModel> get all => List.unmodifiable(_items);

  List<ItemModel> get filtered {
    final q = _query.trim().toLowerCase();
    final list = _items.where((i) {
      final catOk = _category == 'All' || i.category == _category;
      final qOk = q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.locationDetail.toLowerCase().contains(q);
      return !i.isReturned && catOk && qOk;
    }).toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return list;
  }

  ItemModel? byId(String id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  CampusPin? pinById(String? id) {
    for (final p in pins) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<ItemModel> itemsAt(String buildingId) => _items
      .where((i) => i.buildingId == buildingId && !i.isReturned)
      .toList();

  List<ItemModel> activePostsOf(UserModel? u) =>
      u == null
          ? []
          : _items.where((i) => i.ownerId == u.id && !i.isReturned).toList();

  List<ItemModel> claimHistoryOf(UserModel? u) =>
      u == null ? [] : _items.where((i) => i.claimedBy == u.id).toList();

  void setQuery(String v) {
    _query = v;
    notifyListeners();
  }

  void setCategory(String c) {
    _category = c;
    notifyListeners();
  }

  // ---- Report validation ----
  String? validateRequired(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Enter $label' : null;

  void publish({
    required UserModel owner,
    required ItemStatus status,
    required String name,
    required String category,
    required String buildingId,
    required String locationDetail,
    required String description,
    required bool hasPhoto,
  }) {
    _items = [
      ItemModel(
        id: 'i${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        description: description.trim(),
        category: category,
        buildingId: buildingId,
        locationDetail: locationDetail.trim(),
        status: status,
        postedAt: DateTime.now(),
        ownerId: owner.id,
        hasPhoto: hasPhoto,
      ),
      ..._items,
    ];
    notifyListeners();
  }

  // ---- Admin moderation ----
  // Every method re-checks the actor's role so a non-admin can never trigger
  // these, even if a screen is wired up incorrectly.

  /// Claims waiting for an admin decision.
  int get pendingClaimCount =>
      _items.where((i) => i.isClaimed && !i.isReturned).length;

  String? _requireAdmin(UserModel? actor) =>
      (actor?.isAdmin ?? false) ? null : 'Admin access required.';

  /// Permanently removes a post. Returns an error message, or null on success.
  String? deleteItem(String itemId, UserModel? actor) {
    final denied = _requireAdmin(actor);
    if (denied != null) return denied;
    if (byId(itemId) == null) return 'Item not found.';
    _items = _items.where((i) => i.id != itemId).toList();
    notifyListeners();
    return null;
  }

  /// Clears a pending claim so someone else can claim the item again.
  String? rejectClaim(String itemId, UserModel? actor) {
    final denied = _requireAdmin(actor);
    if (denied != null) return denied;
    final item = byId(itemId);
    if (item == null) return 'Item not found.';
    if (!item.isClaimed || item.isReturned) return 'There is no pending claim.';
    _items = [
      for (final i in _items)
        if (i.id == itemId) i.copyWith(clearClaim: true) else i
    ];
    notifyListeners();
    return null;
  }

  /// Verifies the claim: marks the item as returned to the claimant.
  String? approveClaim(String itemId, UserModel? actor) {
    final denied = _requireAdmin(actor);
    if (denied != null) return denied;
    final item = byId(itemId);
    if (item == null) return 'Item not found.';
    if (!item.isClaimed || item.isReturned) return 'There is no pending claim.';
    _items = [
      for (final i in _items)
        if (i.id == itemId) i.copyWith(isReturned: true) else i
    ];
    notifyListeners();
    return null;
  }

  /// Returns an error message, or null on success.
  String? claim(String itemId, UserModel user) {
    final item = byId(itemId);
    if (item == null) return 'Item not found.';
    if (item.isClaimed) return 'A claim is already pending.';
    if (item.ownerId == user.id) return 'You posted this item.';
    _items = [
      for (final i in _items)
        if (i.id == itemId) i.copyWith(claimedBy: user.id) else i
    ];
    notifyListeners();
    return null;
  }
}
