import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack_pro/main.dart';

void main() {
  testWidgets('shows login screen when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FitTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FitTrack Pro'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
