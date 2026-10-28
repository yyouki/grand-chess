import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/ui/screens/three_d_tower_screen.dart';

void main() {
  testWidgets('tower builder adds a block and can restart', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ThreeDTowerScreen()));
    expect(find.text('SCORE  0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tower-drop-block')));
    await tester.pumpAndSettle();

    expect(find.textContaining('SCORE  '), findsOneWidget);
    expect(find.byKey(const ValueKey('tower-block-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tower-reset')));
    await tester.pumpAndSettle();
    expect(find.text('SCORE  0'), findsOneWidget);
  });
}
