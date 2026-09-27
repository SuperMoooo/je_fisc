// Put your widget tests here; `test/unit/` and `test/integration/` are
// scaffolded for the rest.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the test harness runs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Placeholder()));

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
