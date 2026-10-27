import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/models/listing_draft.dart';
import 'package:campus_marketplace_w7/repositories/favorites_repository_drift.dart';
import 'package:campus_marketplace_w7/repositories/listing_draft_repository_drift.dart';

void main() {
  test(
    'favorites and listing drafts remain available from local storage after reopening',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'listing_draft_test_',
      );
      final databaseFile = File(p.join(tempDirectory.path, 'drafts.sqlite'));
      late AppDatabase database;
      addTearDown(() async {
        await database.close();
        await tempDirectory.delete(recursive: true);
      });

      database = AppDatabase.forTesting(NativeDatabase(databaseFile));
      final repository = ListingDraftRepositoryDrift(database);
      final favoritesRepository = FavoritesRepositoryDrift(database);
      await repository.saveDraft(
        const ListingDraft(
          title: 'Used textbook',
          category: 'Books',
          description: 'Good condition',
        ),
        'image.jpg',
      );
      await favoritesRepository.addFavorite(
        42,
        'Desk lamp',
        250,
        'https://example.com/lamp.jpg',
      );
      await database.close();

      database = AppDatabase.forTesting(NativeDatabase(databaseFile));
      final reopenedRepository = ListingDraftRepositoryDrift(database);
      final reopenedFavoritesRepository = FavoritesRepositoryDrift(database);
      final drafts = await reopenedRepository.getAllDrafts();
      final favorites = await reopenedFavoritesRepository.getAllFavorites();

      expect(drafts, hasLength(1));
      expect(drafts.single.title, 'Used textbook');
      expect(drafts.single.category, 'Books');
      expect(drafts.single.description, 'Good condition');
      expect(drafts.single.imagePath, 'image.jpg');
      expect(favorites, hasLength(1));
      expect(favorites.single.title, 'Desk lamp');
      expect(favorites.single.price, 250);
      expect(favorites.single.imageUrl, 'https://example.com/lamp.jpg');
    },
  );
}
