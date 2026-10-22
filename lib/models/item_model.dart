enum ItemStatus { lost, found }

class ItemModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String buildingId; // matches CampusPin.id
  final String locationDetail; // e.g. "Cafeteria Table near Exit"
  final ItemStatus status;
  final DateTime postedAt;
  final String ownerId;
  final bool hasPhoto;
  final String? claimedBy;

  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.buildingId,
    required this.locationDetail,
    required this.status,
    required this.postedAt,
    required this.ownerId,
    this.hasPhoto = false,
    this.claimedBy,
  });

  bool get isClaimed => claimedBy != null;

  ItemModel copyWith({String? claimedBy}) => ItemModel(
        id: id,
        name: name,
        description: description,
        category: category,
        buildingId: buildingId,
        locationDetail: locationDetail,
        status: status,
        postedAt: postedAt,
        ownerId: ownerId,
        hasPhoto: hasPhoto,
        claimedBy: claimedBy ?? this.claimedBy,
      );

  String get timeAgo {
    final d = DateTime.now().difference(postedAt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  String get preciseTime {
    final h = postedAt.hour % 12 == 0 ? 12 : postedAt.hour % 12;
    final m = postedAt.minute.toString().padLeft(2, '0');
    final ap = postedAt.hour >= 12 ? 'PM' : 'AM';
    return '${postedAt.year}-${postedAt.month.toString().padLeft(2, '0')}-'
        '${postedAt.day.toString().padLeft(2, '0')}  $h:$m $ap';
  }
}

class CampusPin {
  final String id;
  final String room;
  final double dx;
  final double dy;
  const CampusPin(this.id, this.room, this.dx, this.dy);
}
