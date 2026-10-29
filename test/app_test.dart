import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/app/grand_chess_app.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' as engine;
import 'package:grand_chess/chess_engine/chess_engine.dart' hide Color;
import 'package:grand_chess/game/game_controller.dart';
import 'package:grand_chess/ui/screens/game_screen.dart';
import 'package:grand_chess/ui/screens/home_screen.dart';
import 'package:grand_chess/ui/screens/local_game_setup_screen.dart';
import 'package:grand_chess/ui/widgets/chess_board.dart';

import 'ui/test_helpers.dart';

Future<void> startLocalGame(WidgetTester tester) async {
  await tester.pumpWidget(const GrandChessApp());
  await tester.tap(keyed('new-local-game'));
  await tester.pumpAndSettle();
  await tester.tap(keyed('start-game'));
  await tester.pumpAndSettle();
}

GameController runningController(WidgetTester tester) {
  return tester.widget<ChessBoard>(find.byType(ChessBoard)).controller;
}

void main() {
  group('Grand Chess app', () {
    testWidgets('opens on the real Grand Chess home screen', (tester) async {
      await tester.pumpWidget(const GrandChessApp());

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(textOf(tester, 'home-title'), 'A quieter way\nto play.');
      expect(find.text('Start a game'), findsOneWidget);
    });

    testWidgets('no longer shows the foundation placeholder', (tester) async {
      await tester.pumpWidget(const GrandChessApp());

      expect(find.text('Grand Chess — Foundation'), findsNothing);
      expect(find.textContaining('Foundation'), findsNothing);
    });

    testWidgets('New Local Game opens the setup screen', (tester) async {
      await tester.pumpWidget(const GrandChessApp());

      await tester.tap(keyed('new-local-game'));
      await tester.pumpAndSettle();

      expect(find.byType(LocalGameSetupScreen), findsOneWidget);
      expect(keyed('white-name-field'), findsOneWidget);
      expect(keyed('black-name-field'), findsOneWidget);
      expect(keyed('start-game'), findsOneWidget);
    });

    testWidgets('starting a game displays the standard starting position', (
      tester,
    ) async {
      await startLocalGame(tester);

      expect(find.byType(GameScreen), findsOneWidget);
      final position = runningController(tester).gameState.position;
      expect(markerSquares('piece-'), hasLength(32));
      for (var file = 0; file < 8; file++) {
        for (var rank = 0; rank < 8; rank++) {
          final square = Square(file, rank);
          expect(
            pieceOn(tester, square.algebraic),
            position.pieceAt(square),
            reason: 'square ${square.algebraic} must match the engine position',
          );
        }
      }
      expect(
        pieceOn(tester, 'e1'),
        const Piece(engine.Color.white, PieceType.king),
      );
      expect(
        pieceOn(tester, 'd8'),
        const Piece(engine.Color.black, PieceType.queen),
      );
      expect(textOf(tester, 'turn-indicator'), 'White to move');
    });

    testWidgets(
      'selecting e2 and then e4 plays a legal move through the controller and the engine',
      (tester) async {
        await startLocalGame(tester);
        final controller = runningController(tester);
        const e2 = Square(4, 1);
        const e4 = Square(4, 3);
        expect(
          controller.gameState.legalMoves.any(
            (move) => move.from == e2 && move.to == e4,
          ),
          isTrue,
        );

        await tapSquare(tester, 'e2');
        expect(controller.selectedSquare, e2);
        await tapSquare(tester, 'e4');

        expect(sanList(controller), ['e4']);
        expect(controller.selectedSquare, isNull);
        expect(controller.lastMove?.from, e2);
        expect(controller.lastMove?.to, e4);
        expect(controller.gameState.position.sideToMove, engine.Color.black);
        expect(
          pieceOn(tester, 'e4'),
          const Piece(engine.Color.white, PieceType.pawn),
        );
        expect(pieceOn(tester, 'e2'), isNull);
      },
    );

    testWidgets('after e2 to e4 the turn indicator shows Black', (
      tester,
    ) async {
      await startLocalGame(tester);

      await playMoves(tester, ['e2e4']);

      expect(textOf(tester, 'turn-indicator'), 'Black to move');
    });

    testWidgets('after e2 to e4 the move history records the move', (
      tester,
    ) async {
      await startLocalGame(tester);
      expect(keyed('history-empty'), findsOneWidget);

      await playMoves(tester, ['e2e4']);

      expect(keyed('history-empty'), findsNothing);
      expect(textOf(tester, 'move-1-white'), 'e4');
    });
  });
}
