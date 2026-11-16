import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';

class AuthService {
  static const demoCode = '123456';
  static const demoEmail = 'demo@univ.edu';
  static const demoPassword = 'campus123';
  static const _demoUser = UserModel(
    id: 'u1',
    studentId: '2024-88392',
    name: 'Alex Student',
    email: demoEmail,
  );
  static const _accounts = MethodChannel('finder/accounts');

  Future<UserModel> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == demoEmail && password == demoPassword) {
      return _demoUser;
    }
    return _readUser('login', {'email': normalizedEmail, 'password': password});
  }

  Future<UserModel> verifyAndRegister({
    required String studentId,
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    if (code != demoCode) throw Exception('Invalid verification code.');
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == demoEmail || studentId == _demoUser.studentId) {
      throw Exception('An account already uses that email or student ID.');
    }
    return _readUser('register', {
      'studentId': studentId,
      'name': name,
      'email': normalizedEmail,
      'password': password,
    });
  }

  Future<UserModel> _readUser(String method, Map<String, String> args) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw Exception(
          'Install the Android APK to use accounts saved on this device.');
    }
    try {
      final data =
          await _accounts.invokeMapMethod<String, String>(method, args);
      if (data == null) throw Exception('Incorrect email or password.');
      return UserModel(
        id: data['id']!,
        studentId: data['studentId']!,
        name: data['name']!,
        email: data['email']!,
      );
    } on PlatformException catch (error) {
      throw Exception(
          error.message ?? 'Could not access accounts on this device.');
    }
  }
}
