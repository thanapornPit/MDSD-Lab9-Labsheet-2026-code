import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/models/listing_draft.dart';
import 'package:campus_marketplace_w7/repositories/favorites_repository.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/repositories/listing_draft_repository.dart';
import 'package:campus_marketplace_w7/screens/auth_gate.dart';
import 'package:campus_marketplace_w7/screens/login_page.dart';

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() async => [];
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

class _FakeDraftRepository implements ListingDraftRepository {
  @override
  Future<void> deleteDraft(int id) async {}

  @override
  Future<List<ListingDraftRow>> getAllDrafts() async => [];

  @override
  Future<void> saveDraft(ListingDraft draft, String imagePath) async {}
}

void main() {
  testWidgets('auth state changes switch between login and marketplace', (
    tester,
  ) async {
    final authEvents = StreamController<User?>.broadcast();
    addTearDown(authEvents.close);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartModel(),
        child: MaterialApp(
          home: AuthGate(
            authEvents: authEvents.stream,
            itemRepositories: [_FakeItemRepository()],
            favoritesRepository: _FakeFavoritesRepository(),
            draftRepository: _FakeDraftRepository(),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    authEvents.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
    expect(find.text('หรือ'), findsOneWidget);
    final googleButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('google_sign_in_button')),
    );
    expect(
      googleButton.style?.minimumSize?.resolve({}),
      const Size.fromHeight(48),
    );

    authEvents.add(_FakeUser());
    await tester.pumpAndSettle();
    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byTooltip('ออกจากระบบ'), findsOneWidget);

    authEvents.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
