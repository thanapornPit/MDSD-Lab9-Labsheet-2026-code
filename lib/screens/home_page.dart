import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  const HomePage({super.key, required this.repository});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Item> _localItems = [];
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final fetchedItems = await widget.repository.getItems();
    if (mounted) {
      setState(() {
        _localItems = fetchedItems;
        _isDataLoaded = true;
      });
    }
  }

  // ✨ เมธอดสำหรับรับสินค้าใหม่และเพิ่มขึ้นบนสุดของรายการ
  void addLocalItem(Item newItem) {
    setState(() {
      _localItems.insert(0, newItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
        ],
      ),
      body: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : _localItems.isEmpty
              ? const Center(child: Text('ไม่พบสินค้า'))
              : ListView.builder(
                  itemCount: _localItems.length,
                  itemBuilder: (context, index) {
                    final item = _localItems[index];
                    
                    Widget imageWidget;
                    if (item.imageUrl.startsWith('/')) {
                      imageWidget = Image.file(
                        File(item.imageUrl),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      );
                    } else {
                      imageWidget = Image.network(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      );
                    }

                    return ListTile(
                      leading: imageWidget,
                      title: Text(item.title),
                      subtitle: Text('${item.price} บาท'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          context.read<CartModel>().add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว')),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}