import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';
import 'package:grand_chess/game/game_controller.dart';

void main() {
  test('undo and redo restore immutable game states', () {
    final controller = GameController();
    addTearDown(controller.dispose);

    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isFalse);

    controller.selectSquare(const Square(4, 1));
    controller.selectSquare(const Square(4, 3));

    expect(controller.gameState.moveHistory, hasLength(1));
    expect(controller.gameState.position.pieceAt(const Square(4, 3)), isNotNull);
    expect(controller.canUndo, isTrue);
    expect(controller.canRedo, isFalse);

    controller.undoMove();

    expect(controller.gameState.moveHistory, isEmpty);
    expect(controller.gameState.position.pieceAt(const Square(4, 1)), isNotNull);
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isTrue);

    controller.redoMove();

    expect(controller.gameState.moveHistory, hasLength(1));
    expect(controller.gameState.position.pieceAt(const Square(4, 3)), isNotNull);
    expect(controller.canRedo, isFalse);
  });

  test('a new game clears the redo stack', () {
    final controller = GameController();
    addTearDown(controller.dispose);

    controller.selectSquare(const Square(4, 1));
    controller.selectSquare(const Square(4, 3));
    controller.undoMove();
    expect(controller.canRedo, isTrue);

    controller.newGame();

    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isFalse);
    expect(controller.gameState.moveHistory, isEmpty);
  });
}
