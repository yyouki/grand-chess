import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  group('Checkmate detection', () {
    test("Fool's mate is recognized as checkmate", () {
      final state = GameState.fromFen(
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
      ).valueOrNull!;
      expect(state.status, GameStatus.checkmate);
      expect(state.isInCheck, isTrue);
      expect(state.legalMoves, isEmpty);
      expect(state.result, GameResult.blackWins);
    });

    test("Scholar's mate is recognized as checkmate", () {
      final state = GameState.fromFen(
        'r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4',
      ).valueOrNull!;
      expect(state.status, GameStatus.checkmate);
      expect(state.result, GameResult.whiteWins);
    });

    test('back-rank mate is delivered by a rook move and detected afterward', () {
      final before = GameState.fromFen(
        '6k1/5ppp/8/8/8/8/8/4R1K1 w - - 0 1',
      ).valueOrNull!;
      expect(before.status, GameStatus.ongoing);

      final after = before
          .applyMove(
            Move(from: Square.fromAlgebraic('e1'), to: Square.fromAlgebraic('e8')),
          )
          .valueOrNull!;
      expect(after.status, GameStatus.checkmate);
      expect(after.result, GameResult.whiteWins);
      expect(after.legalMoves, isEmpty);
    });

    test('checkmate is never confused with an ordinary check', () {
      final state = GameState.fromFen(
        'R3k3/8/8/8/8/8/8/4K3 b - - 0 1',
      ).valueOrNull!;
      expect(state.isInCheck, isTrue);
      expect(state.status, isNot(GameStatus.checkmate));
      expect(state.status, GameStatus.ongoing);
    });
  });
}
