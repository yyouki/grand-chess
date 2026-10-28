import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/app/grand_chess_app.dart';
import 'package:grand_chess/ui/widgets/chess_board.dart';
import 'package:grand_chess/ui/widgets/move_history_panel.dart';

import 'test_helpers.dart';

const List<Size> singleColumnSizes = <Size>[
  Size(320, 568),
  Size(360, 740),
  Size(390, 844),
  Size(800, 1100),
];

const List<Size> sideBySideSizes = <Size>[
  Size(1280, 800),
  Size(1024, 768),
  Size(800, 360),
  Size(720, 400),
];

String describe(Size size) => '${size.width.toInt()}x${size.height.toInt()}';

void expectSingleColumn(WidgetTester tester, Size screen) {
  final board = tester.getRect(find.byType(ChessBoard));
  final history = tester.getRect(find.byType(MoveHistoryPanel));
  expect(board.width, closeTo(board.height, 0.01));
  expect(board.left, greaterThanOrEqualTo(0));
  expect(board.right, lessThanOrEqualTo(screen.width));
  expect(history.top, greaterThanOrEqualTo(board.bottom));
  expect(tester.takeException(), isNull);
}

void expectSideBySide(WidgetTester tester, Size screen) {
  final board = tester.getRect(find.byType(ChessBoard));
  final history = tester.getRect(find.byType(MoveHistoryPanel));
  expect(board.width, closeTo(board.height, 0.01));
  expect(board.left, greaterThanOrEqualTo(0));
  expect(board.bottom, lessThanOrEqualTo(screen.height));
  expect(history.left, greaterThanOrEqualTo(board.right));
  expect(history.right, lessThanOrEqualTo(screen.width));
  expect(tester.takeException(), isNull);
}

void main() {
  group('game screen layout', () {
    for (final size in singleColumnSizes) {
      testWidgets('uses a single column on a ${describe(size)} portrait screen', (
        tester,
      ) async {
        useScreenSize(tester, size);

        await pumpGameScreen(tester);

        expectSingleColumn(tester, size);
      });
    }

    for (final size in sideBySideSizes) {
      testWidgets('puts the board beside the sidebar on a ${describe(size)} screen', (
        tester,
      ) async {
        useScreenSize(tester, size);

        await pumpGameScreen(tester);

        expectSideBySide(tester, size);
      });
    }

    testWidgets('switches layout when the window size changes', (tester) async {
      const phone = Size(360, 740);
      const desktop = Size(1280, 800);
      useScreenSize(tester, phone);
      await pumpGameScreen(tester);
      expectSingleColumn(tester, phone);

      useScreenSize(tester, desktop);
      await tester.pumpAndSettle();
      expectSideBySide(tester, desktop);

      useScreenSize(tester, phone);
      await tester.pumpAndSettle();
      expectSingleColumn(tester, phone);
    });

    testWidgets('the board is playable on a phone screen', (tester) async {
      useScreenSize(tester, const Size(360, 740));
      await pumpGameScreen(tester);

      await playMoves(tester, ['e2e4', 'e7e5']);

      expect(textOf(tester, 'move-1-white'), 'e4');
      expect(textOf(tester, 'move-1-black'), 'e5');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the board is playable on a desktop window', (tester) async {
      useScreenSize(tester, const Size(1280, 800));
      await pumpGameScreen(tester);

      await playMoves(tester, ['e2e4', 'e7e5']);
      await dragPiece(tester, 'g1', 'f3');

      expect(textOf(tester, 'move-2-white'), 'Nf3');
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the history readable after a long opening', (
      tester,
    ) async {
      useScreenSize(tester, const Size(360, 740));
      await pumpGameScreen(tester);

      await playMoves(tester, [
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1b5',
        'a7a6',
        'b5a4',
        'g8f6',
        'e1g1',
        'f8e7',
      ]);
      await tester.pumpAndSettle();

      expect(textOf(tester, 'move-3-white'), 'Bb5');
      expect(textOf(tester, 'move-5-white'), 'O-O');
      expect(textOf(tester, 'move-5-black'), 'Be7');
      expect(textOf(tester, 'turn-indicator'), 'White to move');
      expect(tester.takeException(), isNull);
    });
  });

  group('dialogs on a small phone', () {
    testWidgets('the promotion dialog fits', (tester) async {
      useScreenSize(tester, const Size(320, 568));
      await pumpGameScreen(tester, fen: promotionFen);

      await tapSquare(tester, 'e7');
      await tapSquare(tester, 'e8');
      await tester.pumpAndSettle();

      expect(keyed('promotion-title'), findsOneWidget);
      expect(keyed('promotion-knight'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the result dialog fits', (tester) async {
      useScreenSize(tester, const Size(320, 568));

      await pumpGameScreen(tester, fen: foolsMateFen);

      expect(keyed('result-title'), findsOneWidget);
      expect(keyed('result-new-game'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('home and setup screens', () {
    for (final size in const <Size>[Size(320, 568), Size(1280, 800)]) {
      testWidgets('lay out without overflow on a ${describe(size)} screen', (
        tester,
      ) async {
        useScreenSize(tester, size);

        await tester.pumpWidget(const GrandChessApp());
        expect(keyed('new-local-game'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(keyed('new-local-game'));
        await tester.pumpAndSettle();

        expect(keyed('start-game'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
