class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  // แปลงจาก JSON (ตอนดึงข้อมูลจาก API หรือฐานข้อมูล)
  factory Item.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
    final title = json['title'] as String? ?? '';
    final price = json['price'] != null ? (json['price'] as num).toDouble() : 0.0;
    final description = json['description'] as String? ?? '';
    final category = json['category'] as String? ?? 'General';
    final imageUrl = json['image'] as String? ?? json['imageUrl'] as String? ?? '';

    return Item(
      id: id,
      title: title,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
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
}