import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';
import 'item_repository_local.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  @override
  Future<List<Item>> getItems() async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('ไม่สามารถโหลดรายการสินค้าได้ (สถานะ ${response.statusCode})');
    } on TimeoutException {
      return ItemRepositoryLocal().getItems();
    } on http.ClientException {
      return ItemRepositoryLocal().getItems();
    } on FormatException {
      return ItemRepositoryLocal().getItems();
    } catch (e) {
      return ItemRepositoryLocal().getItems();
    }
  }
}