import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<ListingDraft> analyzeProductImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final imagePart = DataPart('image/jpeg', bytes);

    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
    );

    // ปรับ Prompt ให้ AI ตอบกลับมาในรูปแบบ JSON ตรงๆ
    final prompt = TextPart(
      '''วิเคราะห์รูปภาพสินค้าชิ้นนี้สำหรับแอปพลิเคชันตลาดนัดนักศึกษา และตอบกลับมาในรูปแบบ JSON format เท่านั้น โดยมี key 3 ตัวดังนี้:
      "title": "ชื่อสินค้าที่กระชับและน่าสนใจ",
      "category": "หมวดหมู่สินค้า เช่น เสื้อผ้า, อุปกรณ์การเรียน, อิเล็กทรอนิกส์",
      "description": "คำอธิบายรายละเอียดสินค้าอย่างน่าดึงดูด"''',
    );

    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final responseText = response.text;
    if (responseText == null) {
      throw Exception('ไม่ได้รับข้อมูลตอบกลับจาก Gemini');
    }

    // ทำความสะอาดข้อความเผื่อมี Markdown code block เช่น ```json ... ```
    String cleanedJsonText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

    // แปลงข้อความ JSON เป็น Map
    final Map<String, dynamic> jsonMap = jsonDecode(cleanedJsonText);

    return ListingDraft.fromJson(jsonMap);
  }
}