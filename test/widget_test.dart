// การทดสอบเริ่มต้น (Smoke Test) ของโปรเจกต์นี้
//
// หมายเหตุสำคัญ 2 ข้อ (ทำไมเทสนี้ไม่ pump MyApp() ตรง ๆ)
//
// 1) MyApp (ใน main.dart) อ้างอิง CartModel ผ่าน context.watch<CartModel>()
//    แต่ ChangeNotifierProvider<CartModel> ถูกครอบไว้ "นอก" MyApp ในฟังก์ชัน main()
//    เท่านั้น ไม่ได้อยู่ใน MyApp เอง ตอนเทส pumpWidget(MyApp()) จึงไม่มี Provider
//    ให้ widget หา เกิด ProviderNotFoundException ทันที ในเทสนี้จึงต้องครอบ
//    ChangeNotifierProvider ให้เองตรงนี้ด้วย
//
// 2) HomePage loads items from every repository in initState(). This test uses
//    fake repositories so it can reliably check the loading and source badges.
//
// เรื่อง Widget Testing แบบเต็มรูปแบบ (รวมถึงการจำลอง Mock/Fake แบบนี้) จะเรียน
// ละเอียดในสัปดาห์ที่ 10

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/repositories/favorites_repository.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/screens/home_page.dart';

/// Repository ปลอมสำหรับใช้ในการทดสอบนี้เท่านั้น ไม่เรียกเครือข่ายจริง
/// Future ที่คืนไปจะ "ค้าง" อยู่ตลอด (ไม่มีวัน complete) เพื่อให้ทดสอบจับสถานะ
/// "กำลังโหลด" (CircularProgressIndicator) ได้แน่นอนทุกครั้งที่รัน
class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository({this.items});

  List<Item>? items;

  @override
  Future<List<Item>> getItems() {
    return items == null ? Completer<List<Item>>().future : Future.value(items);
  }
}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<void> addFavorite(
    int itemId,
    String title,
    double price,
    String imageUrl,
  ) async {}

  @override
  Future<List<FavoriteItem>> getAllFavorites() async => [];

  @override
  Future<void> removeFavorite(int itemId) async {}
}

void main() {
  testWidgets('แอปเปิดขึ้นมาแสดงชื่อแอปและสถานะกำลังโหลดสินค้า', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          title: 'Campus Marketplace',
          home: HomePage(
            repositories: [_FakeItemRepository()],
            favoritesRepository: _FakeFavoritesRepository(),
          ),
        ),
      ),
    );

    // ยังไม่ pumpAndSettle เพราะ _FakeItemRepository.getItems() ไม่มีวัน complete
    // (ตั้งใจให้ค้างสถานะ "กำลังโหลด" ไว้) ต้องการแค่ตรวจสอบสถานะเริ่มต้นเท่านั้น
    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('รวมสินค้าจากทุกรายการและแสดงป้ายแหล่งที่มา', (
    WidgetTester tester,
  ) async {
    final apiItem = Item(
      id: 1,
      title: 'สินค้าจาก API',
      price: 10,
      description: '',
      category: 'General',
      imageUrl: '',
    );
    final firestoreItem = Item(
      id: 2,
      title: 'สินค้าจากนักศึกษา',
      price: 20,
      description: '',
      category: 'General',
      imageUrl: '',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          home: HomePage(
            repositories: [
              _FakeItemRepository(items: [apiItem]),
              _FakeItemRepository(items: [firestoreItem]),
            ],
            favoritesRepository: _FakeFavoritesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('สินค้าจาก API'), findsOneWidget);
    expect(find.text('สินค้าจากนักศึกษา'), findsOneWidget);
    expect(find.text('API'), findsOneWidget);
    expect(find.text('นักศึกษา'), findsOneWidget);
  });

  testWidgets('รีเฟรชรายการสินค้าแล้วแสดงสินค้าที่เพิ่มภายหลัง', (
    WidgetTester tester,
  ) async {
    final repository = _FakeItemRepository(items: []);
    final homeKey = GlobalKey<HomePageState>();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          home: HomePage(
            key: homeKey,
            repositories: [repository],
            favoritesRepository: _FakeFavoritesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ไม่พบสินค้า'), findsOneWidget);

    repository.items = [
      Item(
        id: 3,
        title: 'ประกาศใหม่',
        price: 30,
        description: '',
        category: 'General',
        imageUrl: '',
      ),
    ];
    await homeKey.currentState!.refreshItems();
    await tester.pumpAndSettle();

    expect(find.text('ประกาศใหม่'), findsOneWidget);
  });
}
