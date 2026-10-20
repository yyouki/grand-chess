import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  group('Move application correctness', () {
    test('a quiet move updates the moved piece location and flips side to move', () {
      final state = GameState.initial();
      final after = state
          .applyMove(
            Move(from: Square.fromAlgebraic('e2'), to: Square.fromAlgebraic('e4')),
          )
          .valueOrNull!;
      expect(after.position.pieceAt(Square.fromAlgebraic('e2')), isNull);
      expect(
        after.position.pieceAt(Square.fromAlgebraic('e4')),
        const Piece(Color.white, PieceType.pawn),
      );
      expect(after.position.sideToMove, Color.black);
    });

    test('fullmove number increments only after Black moves', () {
      final afterWhite = GameState.initial()
          .applyMove(
            Move(from: Square.fromAlgebraic('e2'), to: Square.fromAlgebraic('e4')),
          )
          .valueOrNull!;
      expect(afterWhite.position.fullmoveNumber, 1);

      final afterBlack = afterWhite
          .applyMove(
            Move(from: Square.fromAlgebraic('e7'), to: Square.fromAlgebraic('e5')),
          )
          .valueOrNull!;
      expect(afterBlack.position.fullmoveNumber, 2);
    });

    test('a capture removes the captured piece and the capturer occupies its square', () {
      final state = GameState.fromFen(
        '4k2r/8/8/8/8/8/8/4K2R w - - 0 1',
      ).valueOrNull!;
      final after = move(state, 'h1', 'h8');
      expect(
        after.position.pieceAt(Square.fromAlgebraic('h8')),
        const Piece(Color.white, PieceType.rook),
      );
      expect(after.position.pieceAt(Square.fromAlgebraic('h1')), isNull);
    });

    test('the original GameState is never mutated by applyMove', () {
      final original = GameState.initial();
      final originalFen = const FenCodec().toFen(original.position);
      original.applyMove(
        Move(from: Square.fromAlgebraic('e2'), to: Square.fromAlgebraic('e4')),
      );
      expect(const FenCodec().toFen(original.position), originalFen);
    });

    test('applying an illegal move returns an error instead of changing state', () {
      final state = GameState.initial();
      final result = state.applyMove(
        Move(from: Square.fromAlgebraic('e2'), to: Square.fromAlgebraic('e5')),
      );
      expect(result.isErr, isTrue);
    });

    test('applying a move once the game is over returns an error', () {
      final finished = GameState.fromFen(
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
      ).valueOrNull!;
      expect(finished.status, GameStatus.checkmate);
      final result = finished.applyMove(
        Move(from: Square.fromAlgebraic('e1'), to: Square.fromAlgebraic('e2')),
      );
      expect(result.isErr, isTrue);
    });

    test('move history accumulates one MoveRecord per applied move', () {
      var state = GameState.initial();
      state = move(state, 'e2', 'e4');
      state = move(state, 'e7', 'e5');
      state = move(state, 'g1', 'f3');
      expect(state.moveHistory.length, 3);
      expect(state.moveHistory.map((r) => r.san).toList(), ['e4', 'e5', 'Nf3']);
    });
  });
}

GameState move(GameState state, String from, String to) {
  return state
      .applyMove(
        Move(from: Square.fromAlgebraic(from), to: Square.fromAlgebraic(to)),
      )
      .valueOrNull!;
}
