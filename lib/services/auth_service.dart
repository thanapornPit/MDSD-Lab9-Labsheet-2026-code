import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  final FirebaseAuth _auth;

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _googleSignInInitialization ??= _googleSignIn.initialize();
      await _googleSignInInitialization;

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthServiceException(
          'ไม่สามารถยืนยันบัญชี Google ได้ กรุณาลองใหม่อีกครั้ง',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      if (kDebugMode) {
        debugPrint(
          'Google Sign-In failed [${error.code}]: ${error.description}',
        );
        if (error.details != null) {
          debugPrint('Google Sign-In details: ${error.details}');
        }
      }
      throw const AuthServiceException(
        'เข้าสู่ระบบด้วย Google ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  String _messageFor(String code) {
    return switch (code) {
      'email-already-in-use' => 'อีเมลนี้มีบัญชีผู้ใช้อยู่แล้ว',
      'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
      'weak-password' => 'รหัสผ่านไม่ปลอดภัย กรุณาตั้งรหัสผ่านที่คาดเดายากขึ้น',
      'operation-not-allowed' =>
        'ยังไม่เปิดใช้งานการเข้าสู่ระบบด้วยอีเมลและรหัสผ่าน',
      'user-disabled' => 'บัญชีนี้ถูกระงับการใช้งาน',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'too-many-requests' => 'พยายามหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่',
      'network-request-failed' =>
        'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาตรวจสอบการเชื่อมต่อ',
      'requires-recent-login' => 'กรุณาเข้าสู่ระบบใหม่แล้วลองอีกครั้ง',
      _ => 'เกิดข้อผิดพลาดในการยืนยันตัวตน กรุณาลองใหม่อีกครั้ง',
    };
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
