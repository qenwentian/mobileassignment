import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum RegistrationStep { details, verify }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._service);
  final AuthService _service;

  UserModel? _user;
  bool _loading = false;
  String? _error;
  RegistrationStep _step = RegistrationStep.details;
  Map<String, String> _pending = {};

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  RegistrationStep get step => _step;
  String get demoCode => AuthService.demoCode;

  // ---- Validation (kept out of the widgets) ----
  static final _emailRe = RegExp(r'^[\w.+-]+@univ\.edu$', caseSensitive: false);
  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your campus email';
    if (!_emailRe.hasMatch(v.trim())) return 'Use your @univ.edu email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  String? validateRequired(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Enter $label' : null;

  String? validateStudentId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your student ID';
    if (!RegExp(r'^\d{4}-\d{5}$').hasMatch(v.trim())) {
      return 'Format: 2024-12345';
    }
    return null;
  }

  // ---- Actions ----
  Future<bool> login(String email, String password) async {
    _begin();
    try {
      _user = await _service.login(email.trim(), password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> startRegistration({
    required String studentId,
    required String name,
    required String email,
    required String password,
  }) async {
    _begin();
    try {
      await _service.sendVerificationCode(email.trim());
      _pending = {
        'studentId': studentId.trim(),
        'name': name.trim(),
        'email': email.trim(),
      };
      _step = RegistrationStep.verify;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    _begin();
    try {
      _user = await _service.verifyAndRegister(
        studentId: _pending['studentId']!,
        name: _pending['name']!,
        email: _pending['email']!,
        code: code.trim(),
      );
      resetRegistration(notify: false);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  void resetRegistration({bool notify = true}) {
    _step = RegistrationStep.details;
    _pending = {};
    _error = null;
    if (notify) notifyListeners();
  }

  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _fail(Object e) {
    _loading = false;
    _error = e.toString().replaceFirst('Exception: ', '');
    notifyListeners();
  }
}
