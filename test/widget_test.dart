import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/models/item_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/item_service.dart';
import 'package:mobile_app/viewmodels/auth_viewmodel.dart';
import 'package:mobile_app/viewmodels/items_viewmodel.dart';

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'demo@univ.edu');
  await tester.enterText(find.byType(TextField).at(1), 'campus123');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

void main() {
  test('campus email validation accepts international education domains', () {
    final auth = AuthViewModel(AuthService());
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

  testWidgets('FINDER starts at the login screen', (tester) async {
    await tester.pumpWidget(const FinderApp());
    expect(find.text('FINDER'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('empty login input displays a helpful error', (tester) async {
    await tester.pumpWidget(const FinderApp());
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your campus email'), findsOneWidget);
  });

  testWidgets('demo login opens the main application', (
    tester,
  ) async {
    await tester.pumpWidget(const FinderApp());
    await login(tester);
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('registered account can sign in again after logging out', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('finder/accounts');
    const user = {
      'id': 'local-1',
      'studentId': '2026-10203',
      'name': 'Jamie Student',
      'email': 'jamie@usjr.edu.ph',
    };
    var registered = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'register') {
        expect(
            call.arguments,
            {...user}
              ..remove('id')
              ..['password'] = 'demo456');
        registered = true;
        return user;
      }
      return registered &&
              call.arguments['email'] == user['email'] &&
              call.arguments['password'] == 'demo456'
          ? user
          : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const FinderApp());
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
    expect(registered, isFalse);
    await tester.enterText(fields, '123456');
    await tester.tap(find.text('Confirm Code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Jamie Student'), findsOneWidget);
    await tester.tap(find.text('Log out'));
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
    await tester.pumpWidget(const FinderApp());
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

  testWidgets('map pins and route control are reachable in landscape',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FinderApp());
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
    await tester.pumpWidget(const FinderApp());
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
    await tester.pumpWidget(const FinderApp());
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
    await tester.pumpWidget(const FinderApp());
    await login(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Active posts: 1'), findsOneWidget);
    await tester.tap(find.text('Log out'));
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
