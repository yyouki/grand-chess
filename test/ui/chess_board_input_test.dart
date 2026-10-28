import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' as engine;
import 'package:grand_chess/chess_engine/chess_engine.dart' hide Color;
import 'package:grand_chess/ui/widgets/chess_board_3d_renderer.dart';

import 'test_helpers.dart';

const Piece whitePawn = Piece(engine.Color.white, PieceType.pawn);

void main() {
  group('dragging', () {
    testWidgets('selects a pawn first, then taps a legal destination', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);

      await tapSquare(tester, 'e2');
      expect(markerSquares('selected-'), {'e2'});
      expect(markerSquares('legal-'), {'e3', 'e4'});
      await tapSquare(tester, 'e4');

      expect(sanList(controller), ['e4']);
      expect(pieceOn(tester, 'e4'), whitePawn);
      expect(pieceOn(tester, 'e2'), isNull);
      expect(markerSquares('selected-'), isEmpty);
    });

    testWidgets(
      'an illegal destination tap clears selection without moving a piece',
      (tester) async {
        final controller = await pumpBoard(tester);

        await tapSquare(tester, 'e2');
        await tapSquare(tester, 'e5');

        expect(sanList(controller), isEmpty);
        expect(pieceOn(tester, 'e2'), whitePawn);
        expect(pieceOn(tester, 'e5'), isNull);
        expect(markerSquares('selected-'), isEmpty);
        expect(markerSquares('legal-'), isEmpty);
      },
    );

    testWidgets('dragging a piece never makes a chess move', (tester) async {
      final controller = await pumpBoard(tester);

      await dragPiece(tester, 'e2', 'e4');

      expect(sanList(controller), isEmpty);
      expect(pieceOn(tester, 'e2'), whitePawn);
      expect(pieceOn(tester, 'e4'), isNull);
      await tapSquare(tester, 'e2');
      await tapSquare(tester, 'e4');
      expect(sanList(controller), ['e4']);
    });

    testWidgets('drags a piece onto an enemy piece to capture it', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);
      await playMoves(tester, ['e2e4', 'd7d5']);

      await tapSquare(tester, 'e4');
      await tapSquare(tester, 'd5');

      expect(sanList(controller), ['e4', 'd5', 'exd5']);
      expect(pieceOn(tester, 'd5'), whitePawn);
      expect(pieceOn(tester, 'e4'), isNull);
    });

    testWidgets('only a tap on the current side piece selects it', (
      tester,
    ) async {
      await pumpBoard(tester);
      await tapSquare(tester, 'e7');
      expect(markerSquares('selected-'), isEmpty);
      await tapSquare(tester, 'e2');
      expect(markerSquares('selected-'), {'e2'});
      expect(find.byType(Draggable<Square>), findsNothing);
    });

    testWidgets('dragging another piece replaces the current selection', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);
      await tapSquare(tester, 'e2');

      await tapSquare(tester, 'g1');
      await tapSquare(tester, 'f3');

      expect(sanList(controller), ['Nf3']);
    });

    testWidgets(
      'dragging a pawn to the last rank asks for a promotion choice',
      (tester) async {
        final controller = await pumpBoard(tester, fen: promotionFen);

        await tapSquare(tester, 'e7');
        await tapSquare(tester, 'e8');

        expect(controller.isAwaitingPromotionChoice, isTrue);
        expect(sanList(controller), isEmpty);
      },
    );
  });

  group('keyboard', () {
    testWidgets('read-only board ignores keyboard activation', (
      tester,
    ) async {
      final controller = await pumpBoard(tester, canSelect: false);

      await tester.tap(squareFinder('e2'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.selectedSquare, isNull);
      expect(sanList(controller), isEmpty);
      expect(markerSquares('selected-'), isEmpty);
    });

    testWidgets('Escape clears the selection', (tester) async {
      await pumpBoard(tester);
      await tapSquare(tester, 'e2');
      expect(markerSquares('selected-'), {'e2'});

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(markerSquares('selected-'), isEmpty);
    });

    testWidgets('arrow keys move the cursor ring and Enter plays the move', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);
      await tapSquare(tester, 'e2');
      expect(markerSquares('cursor-'), isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(markerSquares('cursor-'), {'e3'});

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sanList(controller), ['e3']);
    });

    testWidgets('Space selects the piece under the cursor', (tester) async {
      await pumpBoard(tester);
      await tapSquare(tester, 'e2');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(markerSquares('selected-'), isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(markerSquares('selected-'), {'e2'});
    });

    testWidgets('arrow keys follow the visual direction on a flipped board', (
      tester,
    ) async {
      final controller = await pumpBoard(tester);
      controller.flipOrientation();
      await tester.pump();
      await tapSquare(tester, 'e2');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(markerSquares('cursor-'), {'e1'});

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(markerSquares('cursor-'), {'d1'});
    });
  });

  group('3D camera', () {
    testWidgets(
      'rotates the perspective view and resets to the default angle',
      (tester) async {
        await pumpBoard(tester);
        final scene = find.byKey(const ValueKey('chess-board-3d-scene'));

        double yaw() {
          final painter = tester.widget<CustomPaint>(scene).painter!;
          return (painter as Chess3DScenePainter).projection.yaw;
        }

        const initialYaw = -0.55;
        expect(yaw(), closeTo(initialYaw, 0.0001));

        final gesture = await tester.startGesture(
          tester.getCenter(squareFinder('d4')),
        );
        await tester.pump();
        await gesture.moveBy(const Offset(70, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(yaw(), isNot(closeTo(initialYaw, 0.01)));
        await tester.tap(keyed('reset-3d-view'));
        await tester.pumpAndSettle();
        expect(yaw(), closeTo(initialYaw, 0.0001));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
