import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' as engine;
import 'package:grand_chess/chess_engine/chess_engine.dart' hide Color;

import 'test_helpers.dart';

const Piece whitePawn = Piece(engine.Color.white, PieceType.pawn);
const Piece blackPawn = Piece(engine.Color.black, PieceType.pawn);
const Piece whiteKing = Piece(engine.Color.white, PieceType.king);
const Piece whiteRook = Piece(engine.Color.white, PieceType.rook);
const Piece whiteQueen = Piece(engine.Color.white, PieceType.queen);

void main() {
  group('initial position', () {
    testWidgets('draws 64 squares and 32 pieces', (tester) async {
      await pumpBoard(tester);

      expect(markerSquares('square-'), hasLength(64));
      expect(markerSquares('piece-'), hasLength(32));
    });

    testWidgets('puts every piece on its standard square', (tester) async {
      await pumpBoard(tester);

      const backRank = <PieceType>[
        PieceType.rook,
        PieceType.knight,
        PieceType.bishop,
        PieceType.queen,
        PieceType.king,
        PieceType.bishop,
        PieceType.knight,
        PieceType.rook,
      ];
      for (var file = 0; file < 8; file++) {
        expect(
          pieceOn(tester, Square(file, 0).algebraic),
          Piece(engine.Color.white, backRank[file]),
        );
        expect(pieceOn(tester, Square(file, 1).algebraic), whitePawn);
        for (var rank = 2; rank <= 5; rank++) {
          expect(pieceOn(tester, Square(file, rank).algebraic), isNull);
        }
        expect(pieceOn(tester, Square(file, 6).algebraic), blackPawn);
        expect(
          pieceOn(tester, Square(file, 7).algebraic),
          Piece(engine.Color.black, backRank[file]),
        );
      }
    });

    testWidgets('shows White at the bottom', (tester) async {
      await pumpBoard(tester);

      expect(isWhiteAtBottom(tester), isTrue);
    });

    testWidgets('labels ranks on the left edge and files on the bottom edge', (
      tester,
    ) async {
      await pumpBoard(tester);

      expect(markerSquares('rank-label-'), {
        for (var rank = 1; rank <= 8; rank++) 'a$rank',
      });
      expect(markerSquares('file-label-'), {
        for (final file in 'abcdefgh'.split('')) '${file}1',
      });
    });
  });

  group('selecting pieces', () {
    testWidgets('highlights a selected pawn and shows its two destinations', (
      tester,
    ) async {
      await pumpBoard(tester);

      await tapSquare(tester, 'e2');

      expect(keyed('selected-e2'), findsOneWidget);
      expect(markerSquares('legal-'), {'e3', 'e4'});
      expect(markerSquares('capture-'), isEmpty);
    });

    testWidgets('shows the two destinations of a knight', (tester) async {
      await pumpBoard(tester);

      await tapSquare(tester, 'g1');

      expect(markerSquares('legal-'), {'f3', 'h3'});
    });

    testWidgets(
      'clears the selection when the selected piece is tapped again',
      (tester) async {
        await pumpBoard(tester);

        await tapSquare(tester, 'e2');
        await tapSquare(tester, 'e2');

        expect(markerSquares('selected-'), isEmpty);
        expect(markerSquares('legal-'), isEmpty);
      },
    );

    testWidgets('moves the selection to another piece of the same side', (
      tester,
    ) async {
      await pumpBoard(tester);

      await tapSquare(tester, 'e2');
      await tapSquare(tester, 'g1');

      expect(markerSquares('selected-'), {'g1'});
      expect(markerSquares('legal-'), {'f3', 'h3'});
    });

    testWidgets(
      'clears the selection when an unrelated empty square is tapped',
      (tester) async {
        await pumpBoard(tester);

        await tapSquare(tester, 'e2');
        await tapSquare(tester, 'e5');

        expect(markerSquares('selected-'), isEmpty);
        expect(markerSquares('legal-'), isEmpty);
      },
    );

    testWidgets('ignores a tap on an opponent piece when nothing is selected', (
      tester,
    ) async {
      await pumpBoard(tester);

      await tapSquare(tester, 'e7');

      expect(markerSquares('selected-'), isEmpty);
      expect(markerSquares('legal-'), isEmpty);
    });
  });

  group('making moves', () {
    testWidgets('moves a pawn two squares and marks the last move', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);

      await playMoves(tester, ['e2e4']);

      expect(pieceOn(tester, 'e4'), whitePawn);
      expect(pieceOn(tester, 'e2'), isNull);
      expect(markerSquares('last-move-'), {'e2', 'e4'});
      expect(markerSquares('selected-'), isEmpty);
      expect(markerSquares('legal-'), isEmpty);
      expect(sanList(controller), ['e4']);
      expect(controller.gameState.position.sideToMove, engine.Color.black);
    });

    testWidgets('lets Black move after White', (tester) async {
      final controller = await pumpBoard(tester);

      await playMoves(tester, ['e2e4', 'e7e5']);

      expect(pieceOn(tester, 'e5'), blackPawn);
      expect(sanList(controller), ['e4', 'e5']);
      expect(controller.gameState.position.sideToMove, engine.Color.white);
      expect(markerSquares('last-move-'), {'e7', 'e5'});
    });

    testWidgets(
      'shows capture markers and captures when the enemy piece is tapped',
      (tester) async {
        final controller = await pumpBoard(tester);
        await playMoves(tester, ['e2e4', 'd7d5']);

        await tapSquare(tester, 'e4');

        expect(markerSquares('legal-'), {'e5'});
        expect(markerSquares('capture-'), {'d5'});

        await tapSquare(tester, 'd5');

        expect(pieceOn(tester, 'd5'), whitePawn);
        expect(pieceOn(tester, 'e4'), isNull);
        expect(sanList(controller), ['e4', 'd5', 'exd5']);
        expect(controller.gameState.moveHistory.last.capturedPiece, blackPawn);
      },
    );

    testWidgets('castles kingside by moving the king two squares', (
      tester,
    ) async {
      final controller = await pumpBoard(tester, fen: castlingFen);

      await tapSquare(tester, 'e1');
      expect(markerSquares('legal-'), {
        'c1',
        'd1',
        'd2',
        'e2',
        'f1',
        'f2',
        'g1',
      });
      await tapSquare(tester, 'g1');

      expect(pieceOn(tester, 'g1'), whiteKing);
      expect(pieceOn(tester, 'f1'), whiteRook);
      expect(pieceOn(tester, 'e1'), isNull);
      expect(pieceOn(tester, 'h1'), isNull);
      expect(sanList(controller), ['O-O']);
    });

    testWidgets('castles queenside by moving the king two squares', (
      tester,
    ) async {
      final controller = await pumpBoard(tester, fen: castlingFen);

      await playMoves(tester, ['e1c1']);

      expect(pieceOn(tester, 'c1'), whiteKing);
      expect(pieceOn(tester, 'd1'), whiteRook);
      expect(pieceOn(tester, 'e1'), isNull);
      expect(pieceOn(tester, 'a1'), isNull);
      expect(sanList(controller), ['O-O-O']);
    });

    testWidgets('captures en passant', (tester) async {
      final controller = await pumpBoard(tester, fen: enPassantFen);

      await tapSquare(tester, 'e5');
      expect(markerSquares('legal-'), {'e6'});
      expect(markerSquares('capture-'), {'d6'});
      await tapSquare(tester, 'd6');

      expect(pieceOn(tester, 'd6'), whitePawn);
      expect(pieceOn(tester, 'd5'), isNull);
      expect(pieceOn(tester, 'e5'), isNull);
      expect(sanList(controller), ['exd6']);
      expect(controller.gameState.moveHistory.single.capturedPiece, blackPawn);
    });
  });

  group('check', () {
    testWidgets('marks the king in check until the check is answered', (
      tester,
    ) async {
      await pumpBoard(tester);

      await playMoves(tester, checkLineMoves);
      expect(keyed('check-e8'), findsOneWidget);

      await playMoves(tester, ['g7g6']);
      expect(keyed('check-e8'), findsNothing);
    });
  });

  group('promotion', () {
    testWidgets('waits for a choice and blocks other input meanwhile', (
      tester,
    ) async {
      final controller = await pumpBoard(tester, fen: promotionFen);

      await tapSquare(tester, 'e7');
      expect(markerSquares('legal-'), {'e8'});
      await tapSquare(tester, 'e8');

      expect(controller.isAwaitingPromotionChoice, isTrue);
      expect(find.byType(Draggable<Square>), findsNothing);
      expect(pieceOn(tester, 'e7'), whitePawn);

      await tapSquare(tester, 'e1');
      expect(markerSquares('selected-'), isEmpty);
      expect(controller.isAwaitingPromotionChoice, isTrue);

      controller.choosePromotion(PieceType.queen);
      await tester.pump();

      expect(pieceOn(tester, 'e8'), whiteQueen);
      expect(pieceOn(tester, 'e7'), isNull);
      expect(sanList(controller), ['e8=Q']);
      expect(controller.isAwaitingPromotionChoice, isFalse);
    });

    testWidgets('cancelling keeps the pawn on its square', (tester) async {
      final controller = await pumpBoard(tester, fen: promotionFen);
      await playMoves(tester, ['e7e8']);
      expect(controller.isAwaitingPromotionChoice, isTrue);

      controller.cancelSelection();
      await tester.pump();

      expect(controller.isAwaitingPromotionChoice, isFalse);
      expect(pieceOn(tester, 'e7'), whitePawn);
      expect(pieceOn(tester, 'e8'), isNull);
      expect(sanList(controller), isEmpty);
      expect(find.byType(Draggable<Square>), findsNWidgets(2));
    });
  });

  group('orientation', () {
    testWidgets('puts Black at the bottom and moves the labels when flipped', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);

      controller.flipOrientation();
      await tester.pump();

      expect(isBlackAtBottom(tester), isTrue);
      expect(markerSquares('rank-label-'), {
        for (var rank = 1; rank <= 8; rank++) 'h$rank',
      });
      expect(markerSquares('file-label-'), {
        for (final file in 'abcdefgh'.split('')) '${file}8',
      });

      controller.flipOrientation();
      await tester.pump();

      expect(isWhiteAtBottom(tester), isTrue);
    });

    testWidgets('keeps square identities when the board is flipped', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);
      controller.flipOrientation();
      await tester.pump();

      await tapSquare(tester, 'e2');

      expect(markerSquares('selected-'), {'e2'});
      expect(markerSquares('legal-'), {'e3', 'e4'});
    });
  });

  group('end of game', () {
    testWidgets('accepts no input after checkmate and marks the mated king', (
      tester,
    ) async {
      final controller = await pumpBoard(tester, fen: foolsMateFen);

      expect(controller.isGameOver, isTrue);
      expect(find.byType(Draggable<Square>), findsNothing);

      await tapSquare(tester, 'e2');
      await tapSquare(tester, 'h4');

      expect(markerSquares('selected-'), isEmpty);
      expect(markerSquares('legal-'), isEmpty);
      expect(keyed('check-e1'), findsOneWidget);
    });
  });
}
