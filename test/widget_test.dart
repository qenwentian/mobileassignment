import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/models/item_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/services/item_service.dart';
import 'package:mobile_app/viewmodels/items_viewmodel.dart';

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'student@example.edu');
  await tester.enterText(find.byType(TextField).at(1), 'campus123');
  await tester.tap(find.text('Log in'));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FINDER starts at the login screen', (tester) async {
    await tester.pumpWidget(const FinderApp());
    expect(find.text('FINDER'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('empty login input displays a helpful error', (tester) async {
    await tester.pumpWidget(const FinderApp());
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('valid simulated login opens the main application', (
    tester,
  ) async {
    await tester.pumpWidget(const FinderApp());
    await login(tester);
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
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
  });

  testWidgets('report form rejects empty required fields', (tester) async {
    await tester.pumpWidget(const FinderApp());
    await login(tester);
    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publish Lost Report'));
    await tester.tap(find.text('Publish Lost Report'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the item name.'), findsOneWidget);
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
    expect(find.text('Log in'), findsOneWidget);
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
