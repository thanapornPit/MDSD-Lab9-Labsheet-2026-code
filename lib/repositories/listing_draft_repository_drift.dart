import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  final AppDatabase _db;

  ListingDraftRepositoryDrift(this._db);

  @override
  Future<void> saveDraft(
    ListingDraft draft,
    String imagePath,
  ) async {
    try {
      final id = await _db.into(_db.listingDrafts).insert(
            ListingDraftsCompanion.insert(
              title: draft.title,
              category: draft.category,
              description: draft.description,
              imagePath: imagePath,
            ),
          );

      final savedDrafts = await _db.select(_db.listingDrafts).get();

      debugPrint('SAVE DRAFT: id=$id');
      debugPrint('TOTAL DRAFTS AFTER SAVE: ${savedDrafts.length}');
      debugPrint('SAVED TITLE: ${draft.title}');
    } catch (e, stackTrace) {
      debugPrint('SAVE DRAFT ERROR: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Future<List<ListingDraftRow>> getAllDrafts() async {
    try {
      final drafts = await (_db.select(_db.listingDrafts)
            ..orderBy([
              (table) => OrderingTerm.desc(table.updatedAt),
            ]))
          .get();

      debugPrint('LOAD DRAFTS: total=${drafts.length}');
      debugPrint('DRAFT TITLES: ${drafts.map((d) => d.title).toList()}');

      return drafts;
    } catch (e, stackTrace) {
      debugPrint('LOAD DRAFTS ERROR: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteDraft(int id) async {
    await (_db.delete(_db.listingDrafts)
          ..where((table) => table.id.equals(id)))
        .go();

    debugPrint('DELETE DRAFT: id=$id');
  }
}
