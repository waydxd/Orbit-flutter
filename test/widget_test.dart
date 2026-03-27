// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_calendar/app.dart';
import 'package:orbit_calendar/ui/core/widgets/orbit_animation.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const OrbitApp());

    // Assert before further frames: auth init moves off splash quickly in tests.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(OrbitAnimation), findsOneWidget);
  });
}
