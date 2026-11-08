import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  ItemRepositoryFirestore({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _items.get();
    return snapshot.docs.map(_itemFromDocument).toList(growable: false);
  }

  Future<void> postItem(Item item) async {
    final currentSellerId = _auth.currentUser?.uid ?? item.sellerId;
    if (currentSellerId == null) {
      throw StateError('ต้องเข้าสู่ระบบก่อนจึงจะลงประกาศสินค้าได้');
    }
    if (item.sellerId != null && item.sellerId != currentSellerId) {
      throw StateError('ไม่สามารถโพสต์สินค้าในบัญชีผู้ขายรายอื่นได้');
    }

    final data = item.toFirestore();
    data['sellerId'] = currentSellerId;
    await _items.add(data);
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _items
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_itemFromDocument).toList(growable: false),
        );
  }

  Item _itemFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    return Item.fromFirestore(document);
  }
}
