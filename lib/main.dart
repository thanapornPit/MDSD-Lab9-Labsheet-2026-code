
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppDatabase _database;
  late final FavoritesRepositoryDrift _favoritesRepository;
  late final ListingDraftRepositoryDrift _draftRepository;

  @override
  void initState() {
    super.initState();

    _database = AppDatabase();
    _favoritesRepository = FavoritesRepositoryDrift(_database);
    _draftRepository = ListingDraftRepositoryDrift(_database);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CartModel>(
      create: (_) => CartModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campus Marketplace',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
          ),
          useMaterial3: true,
        ),
        home: MainScaffold(
          itemRepository: ItemRepositoryApi(),
          favoritesRepository: _favoritesRepository,
          draftRepository: _draftRepository,
        ),
      ),
    );
  }
}
