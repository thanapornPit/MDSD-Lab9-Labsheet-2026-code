import 'package:flutter/material.dart';

import '../models/item.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/auth_service.dart';

import 'home_page.dart';
import 'sell_item_page.dart';
import 'favorites_page.dart';

class MainScaffold extends StatefulWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const MainScaffold({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  }) : assert(itemRepositories.length > 0);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  bool _isSigningOut = false;

  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  void _onItemCreated(Item item) {
    _homePageKey.currentState?.addLocalItem(item);

    setState(() {
      _selectedIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เพิ่มสินค้าลงหน้าหลักเรียบร้อยแล้ว')),
    );
  }

  Future<void> _refreshHomeItems() async {
    await _homePageKey.currentState?.refreshItems();
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      final messenger = ScaffoldMessenger.of(context);
      await AuthService().signOut();
      messenger.showSnackBar(const SnackBar(content: Text('ออกจากระบบแล้ว')));
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ออกจากระบบไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        key: _homePageKey,
        repositories: widget.itemRepositories,
        favoritesRepository: widget.favoritesRepository,
        onSignOut: _signOut,
        isSigningOut: _isSigningOut,
      ),
      SellItemPage(
        draftRepository: widget.draftRepository,
        onItemCreated: _onItemCreated,
        onListingsChanged: _refreshHomeItems,
      ),
      FavoritesPage(repository: widget.favoritesRepository),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
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
