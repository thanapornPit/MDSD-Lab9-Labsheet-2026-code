import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'database/app_database.dart';
import 'firebase_options.dart';
import 'models/cart_model.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: AuthGate(
          itemRepositories: [ItemRepositoryApi(), ItemRepositoryFirestore()],
          favoritesRepository: _favoritesRepository,
          draftRepository: _draftRepository,
        ),
      ),
    );
  }
}
