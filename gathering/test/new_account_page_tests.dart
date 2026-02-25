import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gathering/features/login/login_page.dart';

void main() {
  group('NewAccountPage Validation Tests', () {

    testWidgets('Empty fields show errors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: NewAccountPage()));

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Invalid email shows error', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: NewAccountPage()));

      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Passwords must match', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: NewAccountPage()));

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Valid input navigates to home', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NewAccountPage(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
          },
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'John');
      await tester.enterText(find.byType(TextFormField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
      await tester.enterText(find.byType(TextFormField).at(3), 'password');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

  });
}
