
import 'package:flutter/material.dart';

import '../models/item.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

import 'home_page.dart';
import 'sell_item_page.dart';
import 'favorites_page.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final GlobalKey<HomePageState> _homePageKey =
      GlobalKey<HomePageState>();

  void _onItemCreated(Item item) {
    _homePageKey.currentState?.addLocalItem(item);

    setState(() {
      _selectedIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มสินค้าลงหน้าหลักเรียบร้อยแล้ว'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        key: _homePageKey,
        repository: widget.itemRepository,
        favoritesRepository: widget.favoritesRepository,
      ),
      SellItemPage(
        draftRepository: widget.draftRepository,
        onItemCreated: _onItemCreated,
      ),
      FavoritesPage(
        repository: widget.favoritesRepository,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'ลงขาย',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'รายการโปรด',
          ),
        ],
      ),
    );
  }
}
