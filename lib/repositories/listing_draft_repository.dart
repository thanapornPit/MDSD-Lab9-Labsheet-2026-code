
import '../database/app_database.dart';
import '../models/listing_draft.dart';

abstract class ListingDraftRepository {
  /// บันทึกร่างประกาศลงฐานข้อมูล
  /// รับข้อมูล ListingDraft และ path รูปภาพแยกกัน
  Future<void> saveDraft(
    ListingDraft draft,
    String imagePath,
  );

  /// ดึงร่างประกาศทั้งหมด เรียงจากแก้ไขล่าสุด
  Future<List<ListingDraftRow>> getAllDrafts();

  /// ลบร่างประกาศตาม ID
  Future<void> deleteDraft(int id);
}
