import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryLocal implements ItemRepository {
  @override
  Future<List<Item>> getItems() async {
    return [
      const Item(
        id: 1,
        title: 'เสื้อยืด Campus',
        price: 299,
        description: 'เสื้อยืดสไตล์นักศึกษา สีขาว',
        category: 'เสื้อผ้า',
        imageUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=800&q=80',
      ),
      const Item(
        id: 2,
        title: 'กระเป๋าเป้',
        price: 599,
        description: 'กระเป๋าเป้สะพายไหล่สำหรับใช้งานทุกวัน',
        category: 'อุปกรณ์',
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80',
      ),
      const Item(
        id: 3,
        title: 'หูฟัง Bluetooth',
        price: 899,
        description: 'หูฟังไร้สายสำหรับเรียนและทำงาน',
        category: 'อุปกรณ์ไอที',
        imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?auto=format&fit=crop&w=800&q=80',
      ),
    ];
  }
}