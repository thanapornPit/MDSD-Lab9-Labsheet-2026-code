import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FavoriteItems, ListingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // หาตำแหน่งโฟลเดอร์เก็บฐานข้อมูล
    final dbFolder = await getApplicationDocumentsDirectory();

    // กำหนดชื่อไฟล์ฐานข้อมูล
    final file = File(p.join(dbFolder.path, 'campus_marketplace.sqlite'));

    // แสดงตำแหน่งฐานข้อมูลใน Terminal
    debugPrint('DATABASE PATH: ${file.path}');

    // เชื่อมต่อฐานข้อมูล SQLite
    return NativeDatabase.createInBackground(file);
  });
}
