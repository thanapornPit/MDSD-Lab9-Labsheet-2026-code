
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/gemini_vision_service.dart';
import 'my_drafts_page.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  final void Function(Item item)? onItemCreated;

  const SellItemPage({
    super.key,
    required this.draftRepository,
    this.onItemCreated,
  });

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
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
      final ListingDraft draft =
          await _geminiService.analyzeProductImage(_imageFile!);

      if (!mounted) return;

      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
      });

      _showMessage(
        'AI สร้างร่างประกาศให้แล้ว กรุณาตรวจสอบข้อมูลก่อนบันทึก',
      );
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

  // บันทึกร่างลงฐานข้อมูล SQLite
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
      final draft = ListingDraft(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      // รอให้ฐานข้อมูลบันทึกเสร็จก่อนล้างฟอร์ม
      await widget.draftRepository.saveDraft(
        draft,
        imageFile.path,
      );

      if (!mounted) return;

      _showMessage('บันทึกร่างประกาศเรียบร้อยแล้ว');

      // ล้างเฉพาะข้อมูลบนฟอร์ม
      // ไม่ลบรายการที่บันทึกไว้ใน SQLite
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();

      setState(() {
        _imageFile = null;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('บันทึกร่างไม่สำเร็จ: $e');
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
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
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

              // ยืนยันและบันทึกร่าง
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
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSavingDraft
                      ? 'กำลังบันทึก...'
                      : 'ยืนยันและบันทึกร่างประกาศ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
