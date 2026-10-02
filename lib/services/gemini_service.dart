import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _model = 'gemini-3.5-flash-lite';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ฟังก์ชันเดิมสำหรับส่งข้อความอย่างเดียว
  Future<String> generateText(String prompt) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    
    if (apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณาส่งค่าผ่าน --dart-define=GEMINI_API_KEY=your_key');
    }

    final uri = Uri.parse('$_baseUrl?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('AI ไม่ได้ส่งคำตอบกลับมา (Candidates ว่างเปล่า)');
        }

        final content = candidates[0]['content'];
        final parts = content['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw Exception('โครงสร้างข้อมูลคำตอบจาก AI ไม่ถูกต้อง');
        }

        return parts[0]['text'] as String;
      } else {
        throw Exception('เกิดข้อผิดพลาดจาก Gemini API (สถานะ ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อกับ Gemini API หมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } catch (e) {
      rethrow;
    }
  }

  // ✨ ฟังก์ชันใหม่: สำหรับส่งทั้ง "รูปภาพ" และ "ข้อความ" ไปให้ Gemini วิเคราะห์
  Future<String> generateTextWithImage(String prompt, File imageFile) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    
    if (apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณาส่งค่าผ่าน --dart-define=GEMINI_API_KEY=your_key');
    }

    final uri = Uri.parse('$_baseUrl?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};

    // 1. อ่านไฟล์รูปภาพแล้วแปลงเป็น Base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // 2. กำหนดประเภทของไฟล์ภาพเบื้องต้น (รองรับ .jpg / .png)
    String mimeType = 'image/jpeg';
    if (imageFile.path.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    }

    // 3. จัดโครงสร้าง Body ตามมาตรฐานของ Gemini Multimodal API
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Image
              }
            }
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('AI ไม่ได้ส่งคำตอบกลับมา (Candidates ว่างเปล่า)');
        }

        final content = candidates[0]['content'];
        final parts = content['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw Exception('โครงสร้างข้อมูลคำตอบจาก AI ไม่ถูกต้อง');
        }

        return parts[0]['text'] as String;
      } else {
        throw Exception('เกิดข้อผิดพลาดจาก Gemini API (สถานะ ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อกับ Gemini API หมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } catch (e) {
      rethrow;
    }
  }
}