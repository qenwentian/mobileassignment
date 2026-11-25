import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/models/item_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/item_service.dart';
import 'package:mobile_app/viewmodels/auth_viewmodel.dart';
import 'package:mobile_app/viewmodels/items_viewmodel.dart';

class FakeAuthService extends AuthService {
  FakeAuthService({List<({UserModel user, String password})>? seedUsers}) {
    final initial = seedUsers ??
        [
          (
            user: const UserModel(
              id: 'u1',
              studentId: '2024-88392',
              name: 'Alex Student',
              email: AuthService.demoEmail,
              role: UserRole.normal,
            ),
            password: AuthService.demoPassword,
          ),
          (
            user: const UserModel(
              id: 'admin-1',
              studentId: '2020-00001',
              name: 'Campus Admin',
              email: 'admin@univ.edu',
              role: UserRole.admin,
            ),
            password: 'admin123',
          ),
        ];
    for (final entry in initial) {
      final email = entry.user.email.toLowerCase();
      _profiles[entry.user.id] = entry.user.copyWith(email: email);
      _passwords[email] = entry.password;
      _emailToUid[email] = entry.user.id;
    }
  }

  final Map<String, UserModel> _profiles = {};
  final Map<String, String> _passwords = {};
  final Map<String, String> _emailToUid = {};
  final StreamController<String?> _uidController =
      StreamController<String?>.broadcast();
  final StreamController<void> _profileChanges =
      StreamController<void>.broadcast();

  String? _currentUid;
  int _nextId = 1;
  String? lastPasswordResetEmail;

  @override
  bool get hasCurrentUser => _currentUid != null;

  @override
  Stream<String?> authUidChanges() => _uidController.stream;

  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    return Stream<UserModel?>.multi((controller) {
      controller.add(_profiles[uid]);
      final sub = _profileChanges.stream.listen((_) {
        controller.add(_profiles[uid]);
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final uid = _emailToUid[normalized];
    if (uid == null || _passwords[normalized] != password) {
      throw Exception('Incorrect email or password.');
    }
    _currentUid = uid;
    _uidController.add(uid);
    return _profiles[uid]!;
  }

  @override
  Future<UserModel> verifyAndRegister({
    required String studentId,
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    if (code != AuthService.demoCode) {
      throw Exception('Invalid verification code.');
    }
    final normalized = email.trim().toLowerCase();
    final trimmedStudentId = studentId.trim();
    if (_emailToUid.containsKey(normalized) ||
        _profiles.values.any((u) => u.studentId == trimmedStudentId)) {
      throw Exception('An account already uses that email or student ID.');
    }
    final uid = 'local-${_nextId++}';
    final user = UserModel(
      id: uid,
      studentId: trimmedStudentId,
      name: name.trim(),
      email: normalized,
      role: UserRole.normal,
    );
    _profiles[uid] = user;
    _passwords[normalized] = password;
    _emailToUid[normalized] = uid;
    _currentUid = uid;
    _uidController.add(uid);
    _profileChanges.add(null);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastPasswordResetEmail = email.trim().toLowerCase();
  }

  @override
  Future<void> logout() async {
    _currentUid = null;
    _uidController.add(null);
  }

  @override
  Stream<List<UserModel>> watchAllUsers() {
    List<UserModel> sorted() => _profiles.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Stream<List<UserModel>>.multi((controller) {
      controller.add(sorted());
      final sub = _profileChanges.stream.listen((_) {
        controller.add(sorted());
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    final existing = _profiles[uid];
    if (existing == null) throw Exception('User not found.');
    _profiles[uid] = existing.copyWith(role: role);
    _profileChanges.add(null);
  }
}

Future<void> login(
  WidgetTester tester, {
  String email = 'demo@univ.edu',
  String password = 'campus123',
}) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

void main() {
  test('campus email validation accepts international education domains', () {
    final auth = AuthViewModel(FakeAuthService());
    addTearDown(auth.dispose);
    for (final email in [
      'alex@school.edu',
      '  Jamie.Olsen+demo@apps.USJR.EDU.PH ',
      'student@school.edu.au',
      'student@school.ac.uk',
    ]) {
      expect(auth.validateEmail(email), isNull, reason: email);
    }
    for (final email in [
      'student@gmail.com',
      'student@usjr.edu,ph',
      'student@usjr.edu.ph.example.com',
      'student@-school.edu',
      'student@.edu',
      'first..last@school.edu',
    ]) {
      expect(auth.validateEmail(email), isNotNull, reason: email);
    }
  });

  test('UserModel parses roles and serializes to Firestore format', () {
    final admin = UserModel.fromMap('u-admin', {
      'studentId': '2020-00001',
      'name': 'Admin User',
      'email': 'admin@univ.edu',
      'role': 'admin',
    });
    expect(admin.role, UserRole.admin);
    expect(admin.isAdmin, isTrue);
    expect(admin.toFirestore(), {
      'studentId': '2020-00001',
      'name': 'Admin User',
      'email': 'admin@univ.edu',
      'role': 'admin',
    });

    for (final raw in ['normal', 'other', null]) {
      final user = UserModel.fromMap('u-norm', {
        'studentId': '2024-00001',
        'name': 'Normal User',
        'email': 'user@univ.edu',
        'role': raw,
      });
      expect(user.role, UserRole.normal);
      expect(user.isAdmin, isFalse);
    }
  });

  test('normal user cannot update user roles via AuthViewModel', () async {
    final fakeAuth = FakeAuthService();
    final vm = AuthViewModel(fakeAuth);
    addTearDown(vm.dispose);

    final ok = await vm.login(AuthService.demoEmail, AuthService.demoPassword);
    expect(ok, isTrue);
    expect(vm.isAdmin, isFalse);
    expect(vm.role, UserRole.normal);

    final err = await vm.updateUserRole('admin-1', UserRole.normal);
    expect(err, 'Admin access required.');
  });

  test('admin can update another user role but cannot self-demote', () async {
    final fakeAuth = FakeAuthService();
    final vm = AuthViewModel(fakeAuth);
    addTearDown(vm.dispose);

    final ok = await vm.login('admin@univ.edu', 'admin123');
    expect(ok, isTrue);
    expect(vm.isAdmin, isTrue);
    expect(vm.role, UserRole.admin);

    final selfErr = await vm.updateUserRole('admin-1', UserRole.normal);
    expect(selfErr, 'You cannot remove your own admin role.');

    final updateErr = await vm.updateUserRole('u1', UserRole.admin);
    expect(updateErr, isNull);

    final users = await vm.watchAllUsers().first;
    final promoted = users.firstWhere((u) => u.id == 'u1');
    expect(promoted.role, UserRole.admin);
    expect(promoted.isAdmin, isTrue);
  });

  test('sendPasswordReset forwards normalized email to AuthService', () async {
    final fakeAuth = FakeAuthService();
    final vm = AuthViewModel(fakeAuth);
    addTearDown(vm.dispose);

    final err = await vm.sendPasswordReset('  Student@USJR.EDU.PH ');
    expect(err, isNull);
    expect(fakeAuth.lastPasswordResetEmail, 'student@usjr.edu.ph');
  });

  testWidgets('FINDER starts at the login screen', (tester) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    expect(find.text('FINDER'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('empty login input displays a helpful error', (tester) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your campus email'), findsOneWidget);
  });

  testWidgets('demo login opens the main application', (tester) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await login(tester);
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('registered account can sign in again after logging out', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(FinderApp(authService: fakeAuth));
    await tester.tap(find.text('Need an account? Register'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '2026-10203');
    await tester.enterText(fields.at(1), 'Jamie Student');
    await tester.enterText(fields.at(2), 'Jamie@usjr.edu.ph');
    await tester.enterText(fields.at(3), 'demo456');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(fields, '654321');
    await tester.tap(find.text('Confirm Code'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid verification code.'), findsOneWidget);
    await tester.enterText(fields, '123456');
    await tester.tap(find.text('Confirm Code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Jamie Student'), findsOneWidget);
    await tester.ensureVisible(find.text('[ LOG OUT ]'));
    await tester.tap(find.text('[ LOG OUT ]'));
    await tester.pumpAndSettle();

    await tester.enterText(fields.at(0), 'JAMIE@usjr.edu.ph');
    await tester.enterText(fields.at(1), 'incorrect');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);
    await tester.enterText(fields.at(1), 'demo456');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Campus Lost & Found'), findsOneWidget);
  });

  testWidgets('item card opens details and directions focus the map', (
    tester,
  ) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await login(tester);
    await tester.tap(find.text('MacBook Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Geology Building, Lab 302'), findsOneWidget);
    await tester.tap(find.text('Directions'));
    await tester.pumpAndSettle();
    expect(find.text('Campus locations'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) {
      final image = widget is Image ? widget.image : null;
      return image is AssetImage && image.assetName == 'assets/campus_map.png';
    }), findsOneWidget);
    expect(find.text('Lab 302'), findsOneWidget);
  });

  testWidgets('map pins and route control are reachable in landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(720, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await login(tester);
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Main Library, 2nd Fl'), findsOneWidget);
    await tester.ensureVisible(find.text('Preview Route'));
    await tester.tap(find.text('Preview Route'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('report form rejects empty required fields', (tester) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await login(tester);
    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publish Lost Report'));
    await tester.tap(find.text('Publish Lost Report'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the item name'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Choose a building'), findsOneWidget);
  });

  testWidgets('valid report appears in the feed', (tester) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await login(tester);
    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Red backpack');
    await tester.enterText(fields.at(1), 'Library reading room');
    await tester.enterText(fields.at(2), 'Red canvas bag with a name tag');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).at(0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).at(1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publish Lost Report'));
    await tester.tap(find.text('Publish Lost Report'));
    await tester.pumpAndSettle();
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.text('Red backpack'), findsOneWidget);
  });

  testWidgets('logout returns to login', (tester) async {
    await tester.pumpWidget(FinderApp(authService: FakeAuthService()));
    await login(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Active Posts (1)'), findsOneWidget);
    await tester.ensureVisible(find.text('[ LOG OUT ]'));
    await tester.tap(find.text('[ LOG OUT ]'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });

  test('sample items have unique IDs and valid statuses', () {
    final items = ItemService().seed();
    expect(items.length, greaterThanOrEqualTo(7));
    expect(items.map((item) => item.id).toSet().length, items.length);
    expect(
      items.every((item) => ItemStatus.values.contains(item.status)),
      isTrue,
    );
  });

  test('search and category filters work together', () {
    final vm = ItemsViewModel(ItemService());
    vm.setCategory('Electronics');
    vm.setQuery('earbuds');
    expect(vm.filtered.map((item) => item.name), ['Wireless Earbuds']);
    vm.setQuery('not found');
    expect(vm.filtered, isEmpty);
  });

  test('publishing adds a report and claims update state only once', () {
    final vm = ItemsViewModel(ItemService());
    const user = UserModel(
      id: 'u1',
      studentId: '1',
      name: 'Demo',
      email: 'demo@example.edu',
    );
    vm.publish(
      owner: user,
      status: ItemStatus.lost,
      name: 'Red backpack',
      category: 'Other',
      buildingId: 'Library',
      locationDetail: 'Reading room',
      description: 'Red canvas bag',
      hasPhoto: false,
    );
    final posted = vm.all.first;
    expect(posted.name, 'Red backpack');
    expect(posted.ownerId, user.id);
    expect(vm.claim('i1', user), isNull);
    expect(vm.byId('i1')!.isClaimed, isTrue);
    expect(vm.claim('i1', user), 'A claim is already pending.');
  });
}
