import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/app/grand_chess_app.dart';
import 'package:grand_chess/ui/screens/game_screen.dart';
import 'package:grand_chess/ui/screens/home_screen.dart';

import '../ui/test_helpers.dart';

Future<void> startGameFromHome(
  WidgetTester tester, {
  String whiteName = '',
  String blackName = '',
}) async {
  await tester.pumpWidget(const GrandChessApp());
  await tester.tap(keyed('new-local-game'));
  await tester.pumpAndSettle();
  if (whiteName.isNotEmpty) {
    await tester.enterText(keyed('white-name-field'), whiteName);
  }
  if (blackName.isNotEmpty) {
    await tester.enterText(keyed('black-name-field'), blackName);
  }
  await tester.tap(keyed('start-game'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plays a game from the home screen to checkmate and starts another', (
    tester,
  ) async {
    await startGameFromHome(tester, whiteName: 'Alice', blackName: 'Bob');

    expect(find.byType(GameScreen), findsOneWidget);
    expect(textOf(tester, 'turn-indicator'), 'Alice (White) to move');
    expect(markerSquares('piece-'), hasLength(32));

    await playMoves(tester, foolsMateMoves);
    await tester.pumpAndSettle();

    expect(textOf(tester, 'result-title'), 'Black wins');
    expect(textOf(tester, 'result-subtitle'), 'Checkmate');

    await tester.tap(keyed('result-new-game'));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'turn-indicator'), 'Alice (White) to move');
    expect(markerSquares('piece-'), hasLength(32));
    expect(keyed('history-empty'), findsOneWidget);
  });

  testWidgets('resigns on a phone screen and navigates back to the home screen', (
    tester,
  ) async {
    useScreenSize(tester, const Size(390, 844));
    await startGameFromHome(tester);
    await playMoves(tester, ['e2e4']);

    await tester.ensureVisible(keyed('resign-button'));
    await tester.pumpAndSettle();
    await tester.tap(keyed('resign-button'));
    await tester.pumpAndSettle();
    await tester.tap(keyed('resign-confirm'));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'result-title'), 'White wins');
    expect(textOf(tester, 'result-subtitle'), 'Black resigned');

    await tester.tap(keyed('result-view-board'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(textOf(tester, 'home-title'), 'Grand Chess');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixes taps and drags in the same game', (tester) async {
    await startGameFromHome(tester);

    await playMoves(tester, ['e2e4']);
    await dragPiece(tester, 'e7', 'e5');
    await playMoves(tester, ['g1f3']);

    expect(textOf(tester, 'move-1-white'), 'e4');
    expect(textOf(tester, 'move-1-black'), 'e5');
    expect(textOf(tester, 'move-2-white'), 'Nf3');
    expect(textOf(tester, 'turn-indicator'), 'Black to move');
  });

  testWidgets('a new game started from the sidebar replaces the old one', (
    tester,
  ) async {
    await startGameFromHome(tester);
    await playMoves(tester, ['e2e4', 'e7e5']);

    await tester.tap(keyed('new-game-button'));
    await tester.pumpAndSettle();
    await tester.tap(keyed('new-game-confirm'));
    await tester.pumpAndSettle();
    await playMoves(tester, ['d2d4']);

    expect(textOf(tester, 'move-1-white'), 'd4');
    expect(keyed('move-2-white'), findsNothing);
    expect(textOf(tester, 'turn-indicator'), 'Black to move');
  });
}
