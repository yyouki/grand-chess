import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' as engine;
import 'package:grand_chess/chess_engine/chess_engine.dart' hide Color;
import 'package:grand_chess/game/game_controller.dart';
import 'package:grand_chess/ui/widgets/chess_board.dart';

import 'test_helpers.dart';

const Piece whitePawn = Piece(engine.Color.white, PieceType.pawn);
const Piece whiteQueen = Piece(engine.Color.white, PieceType.queen);
const Piece whiteRook = Piece(engine.Color.white, PieceType.rook);
const Piece whiteKnight = Piece(engine.Color.white, PieceType.knight);
const Piece whiteBishop = Piece(engine.Color.white, PieceType.bishop);
const Piece blackQueen = Piece(engine.Color.black, PieceType.queen);

const String kingsAndRookFen = '4k3/8/8/8/8/8/8/R3K3 w - - 0 1';
const String kingsAndRookClock99Fen = '4k3/8/8/8/8/8/8/R3K3 w - - 99 50';
const String bareKingsFen = '4k3/8/8/8/8/8/8/4K3 w - - 0 1';
const List<String> repetitionMoves = <String>[
  'e1e2',
  'e8e7',
  'e2e1',
  'e7e8',
  'e1e2',
  'e8e7',
  'e2e1',
  'e7e8',
];

GameController controllerOf(WidgetTester tester) {
  return tester.widget<ChessBoard>(find.byType(ChessBoard)).controller;
}

Future<void> openPromotionDialog(WidgetTester tester) async {
  await pumpGameScreen(tester, fen: promotionFen);
  await tapSquare(tester, 'e7');
  await tapSquare(tester, 'e8');
  await tester.pumpAndSettle();
}

void main() {
  group('status bar and history', () {
    testWidgets('starts with White to move and an empty history', (
      tester,
    ) async {
      await pumpGameScreen(tester);

      expect(textOf(tester, 'turn-indicator'), 'White to move');
      expect(keyed('history-empty'), findsOneWidget);
      expect(keyed('check-indicator'), findsNothing);
      expect(keyed('result-headline'), findsNothing);
    });

    testWidgets('shows the player names next to the side to move', (
      tester,
    ) async {
      await pumpGameScreen(tester, whiteName: 'Alice', blackName: 'Bob');

      expect(textOf(tester, 'turn-indicator'), 'Alice (White) to move');
      await playMoves(tester, ['e2e4']);
      expect(textOf(tester, 'turn-indicator'), 'Bob (Black) to move');
    });

    testWidgets('lists the moves in algebraic notation', (tester) async {
      await pumpGameScreen(tester);

      await playMoves(tester, ['e2e4', 'e7e5', 'g1f3']);

      expect(keyed('history-empty'), findsNothing);
      expect(textOf(tester, 'move-1-white'), 'e4');
      expect(textOf(tester, 'move-1-black'), 'e5');
      expect(textOf(tester, 'move-2-white'), 'Nf3');
      expect(textOf(tester, 'move-2-black'), '');
    });

    testWidgets('warns while the side to move is in check', (tester) async {
      await pumpGameScreen(tester);

      await playMoves(tester, checkLineMoves);

      expect(textOf(tester, 'check-indicator'), 'Check');
      expect(textOf(tester, 'turn-indicator'), 'Black to move');
      expect(textOf(tester, 'move-2-white'), 'Qh5+');

      await playMoves(tester, ['g7g6']);

      expect(keyed('check-indicator'), findsNothing);
    });

    testWidgets('follows changes that are made to the controller directly', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      final controller = controllerOf(tester);

      controller.resign();
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-headline'), 'Black wins');
      expect(textOf(tester, 'result-title'), 'Black wins');
    });
  });

  group('promotion dialog', () {
    testWidgets('offers exactly the four promotion pieces', (tester) async {
      await openPromotionDialog(tester);

      expect(keyed('promotion-title'), findsOneWidget);
      for (final name in ['queen', 'rook', 'bishop', 'knight']) {
        expect(keyed('promotion-$name'), findsOneWidget);
      }
      expect(keyed('promotion-king'), findsNothing);
      expect(keyed('promotion-pawn'), findsNothing);
      expect(pieceOn(tester, 'e7'), whitePawn);
    });

    testWidgets('promotes to a queen and the game continues', (tester) async {
      await openPromotionDialog(tester);

      await tester.tap(keyed('promotion-queen'));
      await tester.pumpAndSettle();

      expect(keyed('promotion-title'), findsNothing);
      expect(keyed('result-title'), findsNothing);
      expect(pieceOn(tester, 'e8'), whiteQueen);
      expect(pieceOn(tester, 'e7'), isNull);
      expect(textOf(tester, 'move-1-white'), 'e8=Q');
      expect(textOf(tester, 'turn-indicator'), 'Black to move');
    });

    testWidgets('promotes to a rook and the game continues', (tester) async {
      await openPromotionDialog(tester);

      await tester.tap(keyed('promotion-rook'));
      await tester.pumpAndSettle();

      expect(pieceOn(tester, 'e8'), whiteRook);
      expect(textOf(tester, 'move-1-white'), 'e8=R');
      expect(keyed('result-title'), findsNothing);
    });

    testWidgets('a knight promotion leaves too little material and draws', (
      tester,
    ) async {
      await openPromotionDialog(tester);

      await tester.tap(keyed('promotion-knight'));
      await tester.pumpAndSettle();

      expect(pieceOn(tester, 'e8'), whiteKnight);
      expect(textOf(tester, 'move-1-white'), 'e8=N');
      expect(textOf(tester, 'result-title'), 'Draw');
      expect(textOf(tester, 'result-subtitle'), 'Insufficient material');
    });

    testWidgets('a bishop promotion leaves too little material and draws', (
      tester,
    ) async {
      await openPromotionDialog(tester);

      await tester.tap(keyed('promotion-bishop'));
      await tester.pumpAndSettle();

      expect(pieceOn(tester, 'e8'), whiteBishop);
      expect(textOf(tester, 'move-1-white'), 'e8=B');
      expect(textOf(tester, 'result-title'), 'Draw');
      expect(textOf(tester, 'result-subtitle'), 'Insufficient material');
    });

    testWidgets('dismissing the dialog cancels the move and allows a retry', (
      tester,
    ) async {
      await openPromotionDialog(tester);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(keyed('promotion-title'), findsNothing);
      expect(pieceOn(tester, 'e7'), whitePawn);
      expect(pieceOn(tester, 'e8'), isNull);
      expect(markerSquares('selected-'), isEmpty);
      expect(keyed('history-empty'), findsOneWidget);
      expect(textOf(tester, 'turn-indicator'), 'White to move');

      await tapSquare(tester, 'e7');
      await tapSquare(tester, 'e8');
      await tester.pumpAndSettle();

      expect(keyed('promotion-title'), findsOneWidget);
    });
  });

  group('end of game', () {
    testWidgets('announces checkmate and who won', (tester) async {
      await pumpGameScreen(tester);

      await playMoves(tester, foolsMateMoves);
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-title'), 'Black wins');
      expect(textOf(tester, 'result-subtitle'), 'Checkmate');
      expect(textOf(tester, 'move-2-black'), 'Qh4#');
    });

    testWidgets('keeps the final board visible and locked after View board', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      await playMoves(tester, foolsMateMoves);
      await tester.pumpAndSettle();

      await tester.tap(keyed('result-view-board'));
      await tester.pumpAndSettle();

      expect(keyed('result-title'), findsNothing);
      expect(textOf(tester, 'result-headline'), 'Black wins');
      expect(textOf(tester, 'result-detail'), 'Checkmate');
      expect(keyed('turn-indicator'), findsNothing);
      expect(pieceOn(tester, 'h4'), blackQueen);
      expect(keyed('check-e1'), findsOneWidget);

      await tapSquare(tester, 'e2');
      expect(markerSquares('selected-'), isEmpty);
      expect(
        tester.widget<IconButton>(keyed('resign-button')).onPressed,
        isNull,
      );
    });

    testWidgets('does not show the result dialog again after View board', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      await playMoves(tester, foolsMateMoves);
      await tester.pumpAndSettle();
      await tester.tap(keyed('result-view-board'));
      await tester.pumpAndSettle();

      await tester.tap(keyed('flip-board'));
      await tester.pumpAndSettle();

      expect(keyed('result-title'), findsNothing);
      expect(isBlackAtBottom(tester), isTrue);
    });

    testWidgets('starts a new game from the result dialog', (tester) async {
      await pumpGameScreen(tester);
      await playMoves(tester, foolsMateMoves);
      await tester.pumpAndSettle();

      await tester.tap(keyed('result-new-game'));
      await tester.pumpAndSettle();

      expect(keyed('result-title'), findsNothing);
      expect(textOf(tester, 'turn-indicator'), 'White to move');
      expect(keyed('history-empty'), findsOneWidget);
      expect(markerSquares('piece-'), hasLength(32));
      expect(pieceOn(tester, 'f2'), whitePawn);
      expect(pieceOn(tester, 'h4'), isNull);
    });

    testWidgets('shows the result at once when the game starts finished', (
      tester,
    ) async {
      await pumpGameScreen(tester, fen: foolsMateFen);

      expect(textOf(tester, 'result-title'), 'Black wins');
      expect(textOf(tester, 'result-subtitle'), 'Checkmate');
    });

    testWidgets('announces stalemate as a draw', (tester) async {
      await pumpGameScreen(tester, fen: stalemateInOneFen);
      expect(keyed('result-title'), findsNothing);

      await playMoves(tester, ['g1g6']);
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-title'), 'Draw');
      expect(textOf(tester, 'result-subtitle'), 'Stalemate');
    });

    testWidgets('announces a draw by the fifty-move rule', (tester) async {
      await pumpGameScreen(tester, fen: kingsAndRookClock99Fen);
      expect(keyed('result-title'), findsNothing);

      await playMoves(tester, ['e1d1']);
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-title'), 'Draw');
      expect(textOf(tester, 'result-subtitle'), 'Fifty-move rule');
    });

    testWidgets('announces a draw by threefold repetition', (tester) async {
      await pumpGameScreen(tester, fen: kingsAndRookFen);

      await playMoves(tester, repetitionMoves.sublist(0, 4));
      await tester.pumpAndSettle();
      expect(keyed('result-title'), findsNothing);

      await playMoves(tester, repetitionMoves.sublist(4));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-title'), 'Draw');
      expect(textOf(tester, 'result-subtitle'), 'Threefold repetition');
    });

    testWidgets('announces insufficient material when the game starts drawn', (
      tester,
    ) async {
      await pumpGameScreen(tester, fen: bareKingsFen);

      expect(textOf(tester, 'result-title'), 'Draw');
      expect(textOf(tester, 'result-subtitle'), 'Insufficient material');
    });
  });

  group('resigning', () {
    testWidgets('asks for confirmation and keeps playing on Cancel', (
      tester,
    ) async {
      await pumpGameScreen(tester);

      await tester.tap(keyed('resign-button'));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'resign-title'), 'White resigns?');

      await tester.tap(keyed('resign-cancel'));
      await tester.pumpAndSettle();

      expect(keyed('resign-title'), findsNothing);
      expect(keyed('result-title'), findsNothing);
      expect(textOf(tester, 'turn-indicator'), 'White to move');
    });

    testWidgets('lets White resign and gives Black the win', (tester) async {
      await pumpGameScreen(tester);

      await tester.tap(keyed('resign-button'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('resign-confirm'));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-title'), 'Black wins');
      expect(textOf(tester, 'result-subtitle'), 'White resigned');
    });

    testWidgets('lets Black resign after White has moved', (tester) async {
      await pumpGameScreen(tester);
      await playMoves(tester, ['e2e4']);

      await tester.tap(keyed('resign-button'));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'resign-title'), 'Black resigns?');
      await tester.tap(keyed('resign-confirm'));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'result-title'), 'White wins');
      expect(textOf(tester, 'result-subtitle'), 'Black resigned');
    });

    testWidgets('locks the board and the Resign button after resigning', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      await tester.tap(keyed('resign-button'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('resign-confirm'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('result-view-board'));
      await tester.pumpAndSettle();

      await tapSquare(tester, 'e2');

      expect(markerSquares('selected-'), isEmpty);
      expect(textOf(tester, 'result-headline'), 'Black wins');
      expect(
        tester.widget<OutlinedButton>(keyed('resign-button')).onPressed,
        isNull,
      );
    });
  });

  group('new game', () {
    testWidgets('starts at once when no move has been played', (tester) async {
      await pumpGameScreen(tester);

      await tester.tap(keyed('new-game-button'));
      await tester.pumpAndSettle();

      expect(find.text('Start a new game?'), findsNothing);
      expect(textOf(tester, 'turn-indicator'), 'White to move');
    });

    testWidgets(
      'asks for confirmation after a move and keeps the game on Cancel',
      (tester) async {
        await pumpGameScreen(tester);
        await playMoves(tester, ['e2e4']);

        await tester.tap(keyed('new-game-button'));
        await tester.pumpAndSettle();
        expect(find.text('Start a new game?'), findsOneWidget);

        await tester.tap(keyed('new-game-cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Start a new game?'), findsNothing);
        expect(textOf(tester, 'turn-indicator'), 'Black to move');
        expect(pieceOn(tester, 'e4'), whitePawn);
      },
    );

    testWidgets('resets the board and the history when confirmed', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      await playMoves(tester, ['e2e4', 'e7e5']);

      await tester.tap(keyed('new-game-button'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('new-game-confirm'));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'turn-indicator'), 'White to move');
      expect(keyed('history-empty'), findsOneWidget);
      expect(pieceOn(tester, 'e2'), whitePawn);
      expect(pieceOn(tester, 'e4'), isNull);
      expect(markerSquares('piece-'), hasLength(32));
    });
  });

  group('board orientation and keyboard', () {
    testWidgets('flips and flips back with the Flip board button', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      expect(isWhiteAtBottom(tester), isTrue);

      await tester.tap(keyed('flip-board'));
      await tester.pumpAndSettle();
      expect(isBlackAtBottom(tester), isTrue);

      await tester.tap(keyed('flip-board'));
      await tester.pumpAndSettle();
      expect(isWhiteAtBottom(tester), isTrue);
    });

    testWidgets('Escape cancels the selection on the game screen', (
      tester,
    ) async {
      await pumpGameScreen(tester);
      await tapSquare(tester, 'e2');
      expect(markerSquares('selected-'), {'e2'});

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(markerSquares('selected-'), isEmpty);
    });
  });
}
