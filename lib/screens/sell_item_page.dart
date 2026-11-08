import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../models/listing_draft.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/gemini_vision_service.dart';
import '../services/storage_service.dart';
import 'my_drafts_page.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  final void Function(Item item)? onItemCreated;
  final Future<void> Function()? onListingsChanged;

  const SellItemPage({
    super.key,
    required this.draftRepository,
    this.onItemCreated,
    this.onListingsChanged,
  });

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController(text: '150');
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final GeminiVisionService _geminiService = GeminiVisionService();

  File? _imageFile;

  bool _isGeneratingAI = false;
  bool _isSavingDraft = false;

  bool get _isBusy => _isGeneratingAI || _isSavingDraft;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // เลือกรูปภาพสินค้า
  Future<void> _pickImage() async {
    if (_isBusy) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() {
        _imageFile = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('เลือกรูปภาพไม่สำเร็จ: $e');
    }
  }

  // ใช้ AI วิเคราะห์รูปภาพและสร้างร่างประกาศ
  Future<void> _generateDraftWithAI() async {
    if (_isBusy) return;

    if (_imageFile == null) {
      _showMessage('กรุณาเลือกรูปภาพสินค้าก่อนใช้ AI');
      return;
    }

    setState(() {
      _isGeneratingAI = true;
    });

    try {
      final ListingDraft draft = await _geminiService.analyzeProductImage(
        _imageFile!,
      );

      if (!mounted) return;

      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
      });

      _showMessage('AI สร้างร่างประกาศให้แล้ว กรุณาตรวจสอบข้อมูลก่อนบันทึก');
    } catch (e) {
      if (!mounted) return;

      _showMessage('AI สร้างร่างไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
        });
      }
    }
  }

  // บันทึกและโพสต์ขายสินค้า
  Future<void> _confirmDraft() async {
    if (_isSavingDraft || _isGeneratingAI) return;

    if (!_formKey.currentState!.validate()) return;

    final imageFile = _imageFile;

    if (imageFile == null) {
      _showMessage('กรุณาเลือกรูปภาพสินค้า');
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });

    try {
      final title = _titleController.text.trim();
      final category = _categoryController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 150.0;

      final draft = ListingDraft(
        title: title,
        category: category,
        description: description,
      );

      // 1. บันทึกร่างลง SQLite
      await widget.draftRepository.saveDraft(draft, imageFile.path);

      // 2. โพสต์ขึ้น Firebase Firestore และ Storage
      final sellerId =
          FirebaseAuth.instance.currentUser?.uid ?? 'student_seller';
      String imageUrl = imageFile.path;
      try {
        imageUrl = await StorageService().uploadListingImage(
          imageFile,
          sellerId,
        );
      } catch (_) {
        // หาก Firebase Storage มีปัญหา ให้ใช้ path รูปในเครื่อง
        imageUrl = imageFile.path;
      }

      final item = Item(
        id: DateTime.now().microsecondsSinceEpoch,
        title: title,
        price: price,
        description: description,
        category: category,
        imageUrl: imageUrl,
        sellerId: sellerId,
      );

      try {
        await ItemRepositoryFirestore().postItem(item);
      } catch (_) {}

      if (!mounted) return;

      // 3. แจ้งเตือนและเพิ่มขึ้นหน้าแรกทันที
      widget.onItemCreated?.call(item);
      widget.onListingsChanged?.call();

      _titleController.clear();
      _priceController.text = '150';
      _categoryController.clear();
      _descriptionController.clear();

      setState(() {
        _imageFile = null;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('โพสต์สินค้าไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
  }

  // เปิดหน้าร่างประกาศของฉัน
  void _openMyDrafts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyDraftsPage(
          repository: widget.draftRepository,
          onListingPosted: widget.onListingsChanged,
        ),
      ),
    );
  }

  // แสดงข้อความแจ้งเตือน
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
        actions: [
          IconButton(
            tooltip: 'ร่างประกาศของฉัน',
            icon: const Icon(Icons.history),
            onPressed: _openMyDrafts,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'สร้างร่างประกาศด้วย AI',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              const Text(
                'เลือกรูปสินค้า แล้วให้ AI ช่วยวิเคราะห์ '
                'และเขียนรายละเอียดประกาศ',
              ),
              const SizedBox(height: 16),

              // ปุ่มเลือกรูปภาพ
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('เลือกรูปภาพจากเครื่อง'),
              ),
              const SizedBox(height: 12),

              // แสดงรูปภาพที่เลือก
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 130,
                        alignment: Alignment.center,
                        color: Colors.grey.shade200,
                        child: const Text('ไม่สามารถแสดงรูปภาพได้'),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 130,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 40),
                      SizedBox(height: 8),
                      Text('ยังไม่ได้เลือกรูปภาพ'),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ปุ่ม AI
              FilledButton.icon(
                onPressed: _isBusy ? null : _generateDraftWithAI,
                icon: _isGeneratingAI
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGeneratingAI
                      ? 'AI กำลังวิเคราะห์รูปภาพ...'
                      : 'AI ช่วยสร้างร่างประกาศ',
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              Text(
                'ตรวจสอบและแก้ไขข้อมูล',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // ชื่อสินค้า
              TextFormField(
                controller: _titleController,
                enabled: !_isBusy,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อสินค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ราคาสินค้า
              TextFormField(
                controller: _priceController,
                enabled: !_isBusy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'ราคา',
                  suffixText: 'บาท',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'กรุณากรอกราคาที่มากกว่า 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // หมวดหมู่สินค้า
              TextFormField(
                controller: _categoryController,
                enabled: !_isBusy,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกหมวดหมู่สินค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // รายละเอียดสินค้า
              TextFormField(
                controller: _descriptionController,
                enabled: !_isBusy,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดสินค้า',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกรายละเอียดสินค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ยืนยันและโพสต์สินค้า
              FilledButton.icon(
                onPressed: _isBusy ? null : _confirmDraft,
                icon: _isSavingDraft
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  _isSavingDraft
                      ? 'กำลังโพสต์ขึ้นหน้าหลัก...'
                      : 'บันทึกและโพสต์ขายสินค้า (ขึ้นหน้าแรกทันที)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
