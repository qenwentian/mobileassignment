import '../models/user_model.dart';

/// Simulated backend. Replace with Firebase/REST calls later.
class AuthService {
  static const demoCode = '123456';

  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (password.length < 6) {
      throw Exception('Incorrect email or password.');
    }
    return UserModel(
      id: 'u1',
      studentId: '2024-88392',
      name: 'Alex Student',
      email: email,
    );
  }

  Future<void> sendVerificationCode(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<UserModel> verifyAndRegister({
    required String studentId,
    required String name,
    required String email,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (code != demoCode) throw Exception('Invalid verification code.');
    return UserModel(id: 'u1', studentId: studentId, name: name, email: email);
  }
}
