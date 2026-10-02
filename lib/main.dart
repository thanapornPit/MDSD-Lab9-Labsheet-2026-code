import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cart_model.dart';
import 'models/item.dart';
import 'repositories/item_repository_api.dart';
import 'screens/home_page.dart';
import 'screens/sell_item_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final GlobalKey<HomePageState> _homePageKey =
      GlobalKey<HomePageState>();

  late final List<Widget> _pages = [
    HomePage(
      key: _homePageKey,
      repository: ItemRepositoryApi(),
    ),
    SellItemPage(
      onItemCreated: _addNewItem,
    ),
  ];

  void _addNewItem(Item item) {
    _homePageKey.currentState?.addLocalItem(item);

    setState(() {
      _currentIndex = 0; // สลับกลับมาหน้าหลักอัตโนมัติ
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่ม "${item.title}" ลงในหน้าหลักแล้ว'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'ลงประกาศขาย',
          ),
        ],
      ),
    );
  }
}