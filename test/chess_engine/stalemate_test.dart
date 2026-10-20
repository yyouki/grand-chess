import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  group('Stalemate detection', () {
    test('king with no legal moves and not in check is stalemate, not checkmate', () {
      final state = GameState.fromFen(
        'k7/8/1Q6/8/8/8/8/7K b - - 0 1',
      ).valueOrNull!;
      expect(state.status, GameStatus.stalemate);
      expect(state.isInCheck, isFalse);
      expect(state.legalMoves, isEmpty);
      expect(state.result, GameResult.draw);
    });

    test('a classic king-and-pawn stalemate is detected', () {
      final state = GameState.fromFen(
        '5k2/5P2/5K2/8/8/8/8/8 b - - 0 1',
      ).valueOrNull!;
      expect(state.status, GameStatus.stalemate);
      expect(state.result, GameResult.draw);
    });

    test('stalemate status is distinct from every other draw reason', () {
      final state = GameState.fromFen(
        'k7/8/1Q6/8/8/8/8/7K b - - 0 1',
      ).valueOrNull!;
      expect(state.status, isNot(GameStatus.drawByFiftyMoveRule));
      expect(state.status, isNot(GameStatus.drawByThreefoldRepetition));
      expect(state.status, isNot(GameStatus.drawByInsufficientMaterial));
      expect(state.status.isDraw, isTrue);
    });
  });
}
