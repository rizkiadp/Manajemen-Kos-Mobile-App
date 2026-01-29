class RoomModel {
  final String id;
  final String roomNumber;
  final String type; // 'VIP', 'Standard', 'Reguler'
  final int floor;
  final String wing; // 'Kiri', 'Kanan', 'Tengah'
  final double price;
  final List<String> facilities; // ['AC', 'WiFi', 'KM Dalam', etc]
  final bool isAvailable;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.floor,
    required this.wing,
    required this.price,
    required this.facilities,
    required this.isAvailable,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      roomNumber: json['roomNumber'] as String,
      type: json['type'] as String,
      floor: json['floor'] as int,
      wing: json['wing'] as String,
      price: (json['price'] as num).toDouble(),
      facilities: List<String>.from(json['facilities'] as List),
      isAvailable: json['isAvailable'] as bool,
      images: List<String>.from(json['images'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'type': type,
      'floor': floor,
      'wing': wing,
      'price': price,
      'facilities': facilities,
      'isAvailable': isAvailable,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isVIP => type == 'VIP';
  bool get isStandard => type == 'Standard';
}
