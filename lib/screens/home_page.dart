import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  final FavoritesRepository favoritesRepository;

  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Item> _localItems = [];
  final Set<int> _favoriteItemIds = {};

  bool _isDataLoaded = false;
  bool _isFavoritesLoaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadFavorites();
  }

  Future<void> _loadItems() async {
    try {
      final fetchedItems = await widget.repository.getItems();

      if (!mounted) return;

      setState(() {
        _localItems = fetchedItems;
        _isDataLoaded = true;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDataLoaded = true;
        _loadError = 'โหลดสินค้าไม่สำเร็จ: $e';
      });
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites =
          await widget.favoritesRepository.getAllFavorites();

      if (!mounted) return;

      setState(() {
        _favoriteItemIds
          ..clear()
          ..addAll(favorites.map((item) => item.itemId));

        _isFavoritesLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFavoritesLoaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โหลดรายการโปรดไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  void addLocalItem(Item newItem) {
    if (!mounted) return;

    setState(() {
      _localItems.insert(0, newItem);
    });
  }

  Future<void> _toggleFavorite(Item item) async {
    if (!_isFavoritesLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กำลังโหลดรายการโปรด กรุณารอสักครู่',
          ),
        ),
      );
      return;
    }

    final isFavorite = _favoriteItemIds.contains(item.id);

    try {
      if (isFavorite) {
        await widget.favoritesRepository.removeFavorite(
          item.id,
        );

        if (!mounted) return;

        setState(() {
          _favoriteItemIds.remove(item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'นำ "${item.title}" ออกจากรายการโปรดแล้ว',
            ),
          ),
        );
      } else {
        await widget.favoritesRepository.addFavorite(
          item.id,
          item.title,
          item.price,
          item.imageUrl,
        );

        if (!mounted) return;

        setState(() {
          _favoriteItemIds.add(item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เพิ่ม "${item.title}" ในรายการโปรดแล้ว',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('จัดการรายการโปรดไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Widget _buildItemImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.image_not_supported),
      );
    }

    if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.broken_image),
          );
        },
      );
    }

    return Image.file(
      File(imageUrl),
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.broken_image),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            tooltip: 'ตะกร้าสินค้า',
            icon: Badge(
              label: Text(
                '${context.watch<CartModel>().itemCount}',
              ),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CheckoutPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isDataLoaded = false;
                              _loadError = null;
                            });
                            _loadItems();
                          },
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    ),
                  ),
                )
              : _localItems.isEmpty
                  ? const Center(
                      child: Text('ไม่พบสินค้า'),
                    )
                  : ListView.builder(
                      itemCount: _localItems.length,
                      itemBuilder: (context, index) {
                        final item = _localItems[index];
                        final isFavorite =
                            _favoriteItemIds.contains(item.id);

                        return ListTile(
                          leading: _buildItemImage(
                            item.imageUrl,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.price} บาท',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: isFavorite
                                    ? 'นำออกจากรายการโปรด'
                                    : 'เพิ่มในรายการโปรด',
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? Colors.red
                                      : null,
                                ),
                                onPressed: () =>
                                    _toggleFavorite(item),
                              ),
                              IconButton(
                                tooltip: 'เพิ่มลงตะกร้า',
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                ),
                                onPressed: () {
                                  context
                                      .read<CartModel>()
                                      .add(item);

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'เพิ่ม "${item.title}" ลงตะกร้าแล้ว',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
