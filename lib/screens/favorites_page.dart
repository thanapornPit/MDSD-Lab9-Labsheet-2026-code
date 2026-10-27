
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;

  const FavoritesPage({
    super.key,
    required this.repository,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.repository != widget.repository) {
      _loadFavorites();
    }
  }

  Future<void> refresh() async {
    _loadFavorites();
    await _favoritesFuture;
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = widget.repository.getAllFavorites();
    });
  }

  Future<void> _removeFavorite(int itemId) async {
    try {
      await widget.repository.removeFavorite(itemId);

      if (!mounted) return;

      _loadFavorites();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบออกจากรายการโปรดแล้ว'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบรายการไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: Text(
            'ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการโปรด'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<FavoriteItem>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'โหลดรายการโปรดไม่สำเร็จ: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadFavorites,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ),
                ],
              );
            }

            final favorites = snapshot.data ?? [];

            if (favorites.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];

                return ListTile(
                  leading: Image.network(
                    item.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '฿${item.price.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    tooltip: 'ลบรายการโปรด',
                    onPressed: () => _removeFavorite(item.itemId),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
