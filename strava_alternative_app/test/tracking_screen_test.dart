import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_pro/features/tracking/tracking_screen.dart';

void main() {
  testWidgets('TrackingScreen shows START button initially', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrackingScreen()));
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsNothing);
  });
}
