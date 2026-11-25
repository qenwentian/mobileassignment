import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum RegistrationStep { details, verify }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._service) {
    _initializing = _service.hasCurrentUser;
    _authSub = _service.authUidChanges().listen(_onAuthUidChanged);
  }

  final AuthService _service;
  StreamSubscription<String?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;
  String? _listeningUid;

  UserModel? _user;
  bool _initializing = false;
  bool _loading = false;
  String? _error;
  RegistrationStep _step = RegistrationStep.details;
  Map<String, String> _pending = {};

  UserModel? get user => _user;
  UserRole get role => _user?.role ?? UserRole.normal;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isAuthenticated => _user != null;
  bool get initializing => _initializing;
  bool get loading => _loading;
  String? get error => _error;
  RegistrationStep get step => _step;
  String get demoCode => AuthService.demoCode;

  static const _emailAtom = r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+";
  static final _emailRe = RegExp(
    '^$_emailAtom(?:\\.$_emailAtom)*@'
    r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+'
    r'(?:edu(?:\.[a-z]{2})?|ac\.[a-z]{2})$',
    caseSensitive: false,
  );

  String? validateEmail(String? v) {
    final email = v?.trim() ?? '';
    if (email.isEmpty) return 'Enter your campus email';
    if (!_emailRe.hasMatch(email)) return 'Use a valid campus email';
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

  void _onAuthUidChanged(String? uid) {
    if (uid == null) {
      _profileSub?.cancel();
      _profileSub = null;
      _listeningUid = null;
      _user = null;
      _initializing = false;
      notifyListeners();
      return;
    }
    if (_listeningUid == uid && _profileSub != null) return;
    _listeningUid = uid;
    _profileSub?.cancel();
    _profileSub = _service.watchUserProfile(uid).listen(
      (profile) {
        if (profile == null) {
          // Ignore transient null snapshots while login/registration is writing the profile.
          if (!_loading) {
            _user = null;
            _initializing = false;
            notifyListeners();
          }
          return;
        }
        _user = profile;
        _initializing = false;
        notifyListeners();
      },
      onError: (Object error) {
        _initializing = false;
        if (!_loading) {
          _error = _cleanError(error);
        }
        notifyListeners();
      },
    );
  }

  Future<bool> login(String email, String password) async {
    if (_loading) return false;
    _begin();
    try {
      _user = await _service.login(email.trim(), password);
      _initializing = false;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  void startRegistration({
    required String studentId,
    required String name,
    required String email,
  }) {
    _pending = {
      'studentId': studentId.trim(),
      'name': name.trim(),
      'email': email.trim(),
    };
    _error = null;
    _step = RegistrationStep.verify;
    notifyListeners();
  }

  Future<bool> verifyCode(String code, String password) async {
    if (_loading || _step != RegistrationStep.verify) return false;
    _begin();
    try {
      _user = await _service.verifyAndRegister(
        studentId: _pending['studentId']!,
        name: _pending['name']!,
        email: _pending['email']!,
        password: password,
        code: code.trim(),
      );
      resetRegistration(notify: false);
      _initializing = false;
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

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordResetEmail(email);
      return null;
    } catch (e) {
      return _cleanError(e);
    }
  }

  Stream<List<UserModel>> watchAllUsers() => _service.watchAllUsers();

  Future<String?> updateUserRole(String uid, UserRole role) async {
    if (!isAdmin) return 'Admin access required.';
    if (uid == _user?.id && role != UserRole.admin) {
      return 'You cannot remove your own admin role.';
    }
    try {
      await _service.updateUserRole(uid, role);
      return null;
    } catch (e) {
      return _cleanError(e);
    }
  }

  Future<void> logout() async {
    _profileSub?.cancel();
    _profileSub = null;
    _listeningUid = null;
    _user = null;
    _error = null;
    _initializing = false;
    notifyListeners();
    try {
      await _service.logout();
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();
    }
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _fail(Object e) {
    _loading = false;
    _error = _cleanError(e);
    notifyListeners();
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
