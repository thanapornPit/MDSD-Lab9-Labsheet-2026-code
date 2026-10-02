import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../models/listing_draft.dart';
import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  final Function(Item) onItemCreated;

  const SellItemPage({super.key, required this.onItemCreated});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _selectedImage;
  bool _isLoading = false;

  // Controllers สำหรับให้ผู้ใช้ตรวจทานและแก้ไขข้อความ (Human-in-the-loop)
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final GeminiVisionService _visionService = GeminiVisionService();

  // ฟังก์ชันเลือกรูปภาพจากแกลเลอรี
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  // ฟังก์ชันเรียกใช้งาน GeminiVisionService เพื่อวิเคราะห์ภาพสินค้า
  Future<void> _analyzeImageWithAI() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าก่อนให้ AI ช่วยแนะนำ')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      ListingDraft draft = await _visionService.analyzeProductImage(_selectedImage!);

      // นำผลลัพธ์จาก AI มาใส่ใน TextField เพื่อให้ผู้ใช้ตรวจสอบและแก้ไขได้ทันที
      setState(() {
        _titleController.text = draft.title;
        _descriptionController.text = draft.description;
        _priceController.text = "150"; // ราคาเริ่มต้นตั้งต้น
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI วิเคราะห์ข้อมูลสินค้าสำเร็จ! กรุณาตรวจสอบก่อนกดยืนยัน')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการวิเคราะห์: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ส่วนแสดงรูปภาพสินค้า
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('ยังไม่ได้เลือกรูปภาพสินค้า',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // ปุ่มเลือกรูปภาพ
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 8),

            // ปุ่มเรียก AI พร้อมแสดงสถานะโหลด
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _analyzeImageWithAI,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'AI กำลังวิเคราะห์ภาพสินค้า...' : 'ให้ AI ช่วยแนะนำ'),
            ),
            const SizedBox(height: 20),

            // ฟอร์มกรอกและแก้ไขข้อมูลสินค้า (Human-in-the-loop)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ราคา (บาท)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'คำอธิบายสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่ม "ยืนยันร่างประกาศ"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกชื่อและราคาสินค้า')),
                  );
                  return;
                }

                final double parsedPrice = double.tryParse(_priceController.text) ?? 0.0;

                // สร้าง Item จากข้อมูลในฟอร์ม (ที่ผู้ใช้ตรวจทานและแก้ไขเรียบร้อยแล้ว)
                final newItem = Item(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: _titleController.text,
                  price: parsedPrice,
                  description: _descriptionController.text,
                  category: 'General',
                  imageUrl: _selectedImage?.path ?? '',
                );

                // ส่งข้อมูลไปยังระบบหลัก (เพื่อไปโชว์ที่หน้าหลัก)
                widget.onItemCreated(newItem);

                // เคลียร์ฟอร์มและรีเซ็ตสถานะกลับเป็นค่าว่าง พร้อมเริ่มลงประกาศใหม่
                setState(() {
                  _titleController.clear();
                  _priceController.clear();
                  _descriptionController.clear();
                  _selectedImage = null;
                });

                // แสดง SnackBar แจ้งเตือนความสำเร็จตามข้อกำหนด (ไม่ต้องใช้ Navigator.pop)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
                );
              },
              child: const Text(
                'ยืนยันร่างประกาศ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}