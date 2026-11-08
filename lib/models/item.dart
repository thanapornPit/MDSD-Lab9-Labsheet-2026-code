import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId;

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
  });

  // แปลงจาก JSON (ตอนดึงข้อมูลจาก API หรือฐานข้อมูล)
  factory Item.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0;
    final title = json['title'] as String? ?? '';
    final price = json['price'] != null
        ? (json['price'] as num).toDouble()
        : 0.0;
    final description = json['description'] as String? ?? '';
    final category = json['category'] as String? ?? 'General';
    final imageUrl =
        json['image'] as String? ?? json['imageUrl'] as String? ?? '';
    final sellerId = json['sellerId'] as String?;

    return Item(
      id: id,
      title: title,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
      sellerId: sellerId,
    );
  }

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('ไม่พบข้อมูลสินค้าใน Firestore');
    }

    return Item(
      id: _idFromDocumentId(doc.id),
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      imageUrl: data['imageUrl'] as String? ?? data['image'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
    );
  }

  // ✨ เพิ่มฟังก์ชันแปลงกลับเป็น Map/JSON (ใช้สำหรับส่งข้อมูลสินค้าใหม่)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': imageUrl,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  static int _idFromDocumentId(String documentId) {
    var hash = 0;
    for (final codeUnit in documentId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
