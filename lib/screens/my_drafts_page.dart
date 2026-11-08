import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;
  final StorageService? storageService;
  final ItemRepositoryFirestore? itemRepository;
  final FirebaseAuth? auth;
  final Future<void> Function()? onListingPosted;

  const MyDraftsPage({
    super.key,
    required this.repository,
    this.storageService,
    this.itemRepository,
    this.auth,
    this.onListingPosted,
  });

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  final Set<int> _postingDraftIds = {};

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  // โหลดร่างจากฐานข้อมูล SQLite
  void _loadDrafts() {
    _draftsFuture = widget.repository.getAllDrafts();
  }

  // โหลดรายการใหม่
  Future<void> _refreshDrafts() async {
    final future = widget.repository.getAllDrafts();

    setState(() {
      _draftsFuture = future;
    });

    await future;
  }

  // ลบร่างเมื่อผู้ใช้ยืนยันเท่านั้น
  Future<void> _deleteDraft(ListingDraftRow draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบร่างประกาศ'),
          content: Text('คุณต้องการลบร่าง "${draft.title}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteDraft(draft.id);

      if (!mounted) return;

      await _refreshDrafts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศเรียบร้อยแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ดำเนินการไม่สำเร็จ: $e')));
    }
  }

  Future<double?> _askForPrice(ListingDraftRow draft) async {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();

    try {
      return await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('กำหนดราคา: ${draft.title}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: priceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'ราคา',
                suffixText: 'บาท',
              ),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                if (price == null || !price.isFinite || price <= 0) {
                  return 'กรุณากรอกราคาที่เป็นตัวเลขและมากกว่า 0';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    double.parse(priceController.text.trim()),
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    double.parse(priceController.text.trim()),
                  );
                }
              },
              child: const Text('โพสต์'),
            ),
          ],
        ),
      );
    } finally {
      priceController.dispose();
    }
  }

  Future<void> _postDraft(ListingDraftRow draft) async {
    if (_postingDraftIds.contains(draft.id)) return;

    final price = await _askForPrice(draft);
    if (price == null || !mounted) return;

    final auth = widget.auth ?? FirebaseAuth.instance;
    final sellerId = auth.currentUser?.uid;
    if (sellerId == null) {
      _showMessage('กรุณาเข้าสู่ระบบก่อนโพสต์สินค้า');
      return;
    }

    final imageFile = File(draft.imagePath);
    final imageExists = await imageFile.exists();
    if (!mounted) return;
    if (!imageExists) {
      _showMessage('ไม่พบรูปภาพของร่างประกาศนี้ กรุณาลบร่างแล้วสร้างใหม่');
      return;
    }

    setState(() {
      _postingDraftIds.add(draft.id);
    });

    try {
      final imageUrl = await (widget.storageService ?? StorageService())
          .uploadListingImage(imageFile, sellerId);
      final item = Item(
        id: DateTime.now().microsecondsSinceEpoch,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: sellerId,
      );

      await (widget.itemRepository ?? ItemRepositoryFirestore()).postItem(item);
      await widget.repository.deleteDraft(draft.id);

      if (!mounted) return;
      await _refreshDrafts();
      await widget.onListingPosted?.call();
      if (!mounted) return;

      _showMessage('โพสต์ "${draft.title}" ขายเรียบร้อยแล้ว');
    } catch (error) {
      if (!mounted) return;
      _showMessage('โพสต์สินค้าไม่สำเร็จ: กรุณาตรวจสอบการเชื่อมต่อเครือข่าย ($error)');
    } finally {
      if (mounted) {
        setState(() {
          _postingDraftIds.remove(draft.id);
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDrafts,
          ),
        ],
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text('โหลดร่างประกาศไม่สำเร็จ'),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refreshDrafts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshDrafts,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Icon(Icons.drafts_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(child: Text('ยังไม่มีร่างประกาศ')),
                  SizedBox(height: 8),
                  Center(child: Text('ร่างที่บันทึกไว้จะแสดงที่นี่')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshDrafts,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: drafts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final draft = drafts[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
                  ),
                  title: Text(
                    draft.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('หมวดหมู่: ${draft.category}'),
                        const SizedBox(height: 4),
                        Text(
                          'แก้ไขล่าสุด: '
                          '${_formatDate(draft.updatedAt)}',
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_postingDraftIds.contains(draft.id))
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          tooltip: 'โพสต์ขายจริง',
                          icon: const Icon(Icons.publish),
                          onPressed: () => _postDraft(draft),
                        ),
                      IconButton(
                        tooltip: 'ลบร่างประกาศ',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: _postingDraftIds.contains(draft.id)
                            ? null
                            : () => _deleteDraft(draft),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
