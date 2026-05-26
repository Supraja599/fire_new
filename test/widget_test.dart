// This is a basic Flutter widget test for the SOS Emergency Platform.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fire_new/main.dart';

void main() {
  setUpAll(() async {
    // Initialize a temporary Hive path for testing
    Hive.init('.');
    await Hive.openBox('inspectionBox');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('Login page elements rendering test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen title and sub-titles are displayed.
    expect(find.text('SYSTEM LOGIN'), findsOneWidget);
    expect(find.text('SOS EMERGENCY PLATFORM'), findsOneWidget);
    expect(find.text('Enter Username'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);
  });
}
