import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/app/grand_chess_app.dart';
import 'package:grand_chess/ui/screens/three_d_tic_tac_toe_screen.dart';

void main() {
  testWidgets('home screen opens the playable 3D arcade', (tester) async {
    await tester.pumpWidget(const GrandChessApp());
    await tester.tap(find.byKey(const ValueKey('open-3d-arcade')));
    await tester.pumpAndSettle();

    expect(find.byType(ThreeDTicTacToeScreen), findsOneWidget);
    expect(find.text('LAYER 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('cube-cell-0')), findsOneWidget);
  });

  testWidgets('3D tic-tac-toe alternates turns and can be restarted', (
    tester,
  ) async {
    await tester.pumpWidget(const GrandChessApp());
    await tester.tap(find.byKey(const ValueKey('open-3d-arcade')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cube-cell-0')));
    await tester.pumpAndSettle();
    expect(find.text('X'), findsWidgets);
    expect(find.text('Player O to move'), findsOneWidget);

    await tester.tap(find.byTooltip('New game'));
    await tester.pumpAndSettle();

    expect(find.text('Player X to move'), findsOneWidget);
  });
}
