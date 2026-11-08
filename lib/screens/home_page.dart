import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final List<ItemRepository> repositories;
  final FavoritesRepository favoritesRepository;
  final VoidCallback? onSignOut;
  final bool isSigningOut;

  const HomePage({
    super.key,
    required this.repositories,
    required this.favoritesRepository,
    this.onSignOut,
    this.isSigningOut = false,
  }) : assert(repositories.length > 0);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<_SourcedItem> _items = [];
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
      final itemGroups = await Future.wait(
        widget.repositories.map((repository) => repository.getItems()),
      );
      final fetchedItems = <_SourcedItem>[
        // แสดงรายการจาก Firestore (นักศึกษา) ก่อน แล้วตามด้วย API
        for (
          var repositoryIndex = itemGroups.length - 1;
          repositoryIndex >= 0;
          repositoryIndex--
        )
          for (final item in itemGroups[repositoryIndex])
            _SourcedItem(item: item, source: _sourceLabel(repositoryIndex)),
      ];

      if (!mounted) return;

      setState(() {
        _items = fetchedItems;
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

  Future<void> refreshItems() async {
    if (!mounted) return;

    setState(() {
      _isDataLoaded = false;
      _loadError = null;
    });
    await _loadItems();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await widget.favoritesRepository.getAllFavorites();

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดรายการโปรดไม่สำเร็จ: $e')));
    }
  }

  void addLocalItem(Item newItem) {
    if (!mounted) return;

    setState(() {
      _items.insert(
        0,
        _SourcedItem(
          item: newItem,
          source: 'นักศึกษา',
        ),
      );
    });
  }

  String _sourceLabel(int repositoryIndex) => switch (repositoryIndex) {
    0 => 'API',
    1 => 'นักศึกษา',
    _ => 'แหล่งข้อมูล ${repositoryIndex + 1}',
  };

  Future<void> _toggleFavorite(Item item) async {
    if (!_isFavoritesLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังโหลดรายการโปรด กรุณารอสักครู่')),
      );
      return;
    }

    final isFavorite = _favoriteItemIds.contains(item.id);

    try {
      if (isFavorite) {
        await widget.favoritesRepository.removeFavorite(item.id);

        if (!mounted) return;

        setState(() {
          _favoriteItemIds.remove(item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('นำ "${item.title}" ออกจากรายการโปรดแล้ว')),
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
          SnackBar(content: Text('เพิ่ม "${item.title}" ในรายการโปรดแล้ว')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('จัดการรายการโปรดไม่สำเร็จ: $e')));
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

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
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
            tooltip: 'ออกจากระบบ',
            icon: widget.isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            onPressed: widget.isSigningOut ? null : widget.onSignOut,
          ),
          IconButton(
            tooltip: 'ตะกร้าสินค้า',
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutPage()),
              );
            },
          ),
        ],
      ),
      body: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
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
          : _items.isEmpty
          ? const Center(child: Text('ไม่พบสินค้า'))
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                final sourcedItem = _items[index];
                final item = sourcedItem.item;
                final isFavorite = _favoriteItemIds.contains(item.id);

                return ListTile(
                  leading: _buildItemImage(item.imageUrl),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SourceBadge(label: sourcedItem.source),
                    ],
                  ),
                  subtitle: Text('${item.price} บาท'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isFavorite
                            ? 'นำออกจากรายการโปรด'
                            : 'เพิ่มในรายการโปรด',
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(item),
                      ),
                      IconButton(
                        tooltip: 'เพิ่มลงตะกร้า',
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          context.read<CartModel>().add(item);

                          ScaffoldMessenger.of(context).showSnackBar(
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
          ),
    );
  }
}

class _SourcedItem {
  const _SourcedItem({required this.item, required this.source});

  final Item item;
  final String source;
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isApi = label == 'API';
    final displayText = isApi ? 'API' : 'me';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isApi
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayText, style: Theme.of(context).textTheme.labelSmall),
          Offstage(
            offstage: true,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
