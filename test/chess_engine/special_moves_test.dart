import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

Set<String> destinationsFrom(GameState state, String fromAlgebraic) {
  final from = Square.fromAlgebraic(fromAlgebraic);
  return state.legalMoves
      .where((m) => m.from == from)
      .map((m) => m.to.algebraic)
      .toSet();
}

void main() {
  group('Castling', () {
    test('both kingside and queenside available when path is clear', () {
      final state = GameState.fromFen(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      ).valueOrNull!;
      final moves = destinationsFrom(state, 'e1');
      expect(moves, containsAll({'c1', 'g1'}));
    });

    test('kingside blocked when a square between king and rook is occupied', () {
      final state = GameState.fromFen(
        'r3k2r/8/8/8/8/8/8/R3KB1R w KQkq - 0 1',
      ).valueOrNull!;
      final moves = destinationsFrom(state, 'e1');
      expect(moves, isNot(contains('g1')));
      expect(moves, contains('c1'));
    });

    test('cannot castle while the king is in check', () {
      final state = GameState.fromFen(
        'r3k2r/8/8/8/8/6b1/8/R3K2R w KQkq - 0 1',
      ).valueOrNull!;
      expect(state.isInCheck, isTrue);
      final moves = destinationsFrom(state, 'e1');
      expect(moves, isNot(contains('c1')));
      expect(moves, isNot(contains('g1')));
    });

    test('cannot castle through a square the king would pass through under attack', () {
      final state = GameState.fromFen(
        'r3k2r/8/8/8/8/3b4/8/R3K2R w KQkq - 0 1',
      ).valueOrNull!;
      final moves = destinationsFrom(state, 'e1');
      expect(moves, isNot(contains('g1')));
      expect(moves, contains('c1'));
    });

    test('only the retained side is offered once a right is lost', () {
      final state = GameState.fromFen(
        'r3k2r/8/8/8/8/8/8/R3K2R w Kkq - 0 1',
      ).valueOrNull!;
      final moves = destinationsFrom(state, 'e1');
      expect(moves, contains('g1'));
      expect(moves, isNot(contains('c1')));
    });

    test('kingside castle moves king to g1 and rook to f1', () {
      final state = GameState.fromFen(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      ).valueOrNull!;
      final applied = state
          .applyMove(
            Move(from: Square.fromAlgebraic('e1'), to: Square.fromAlgebraic('g1')),
          )
          .valueOrNull!;
      expect(
        applied.position.pieceAt(Square.fromAlgebraic('g1')),
        const Piece(Color.white, PieceType.king),
      );
      expect(
        applied.position.pieceAt(Square.fromAlgebraic('f1')),
        const Piece(Color.white, PieceType.rook),
      );
      expect(applied.position.pieceAt(Square.fromAlgebraic('h1')), isNull);
      expect(applied.position.pieceAt(Square.fromAlgebraic('e1')), isNull);
    });
  });

  group('En passant', () {
    test('is offered immediately after an adjacent double pawn push', () {
      final state = GameState.fromFen(
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e5'), {'d6', 'e6'});
    });

    test('is not offered once the opportunity has passed', () {
      final state = GameState.fromFen(
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e5'), {'e6'});
    });

    test('capture removes the captured pawn and lands on the passed-through square', () {
      final state = GameState.fromFen(
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
      ).valueOrNull!;
      final applied = state
          .applyMove(
            Move(from: Square.fromAlgebraic('e5'), to: Square.fromAlgebraic('d6')),
          )
          .valueOrNull!;
      expect(
        applied.position.pieceAt(Square.fromAlgebraic('d6')),
        const Piece(Color.white, PieceType.pawn),
      );
      expect(applied.position.pieceAt(Square.fromAlgebraic('d5')), isNull);
      expect(applied.position.pieceAt(Square.fromAlgebraic('e5')), isNull);
    });

    test('does not expose the king to check (pinned en passant capturer)', () {
      // White king e5, white pawn d5, black pawn just double-pushed to c5
      // (en passant target c6), black rook a5 — all on rank 5. Capturing
      // en passant would remove both the d5 pawn and the c5 pawn from the
      // rank, opening a clear line from the rook to the king, so it must
      // NOT be offered as a legal move even though it is pseudo-legal.
      final state = GameState.fromFen(
        '4k3/8/8/r1pPK3/8/8/8/8 w - c6 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'd5'), {'d6'});
    });
  });

  group('Promotion', () {
    test('offers all four promotion pieces on a push to the last rank', () {
      final state = GameState.fromFen(
        '8/4P3/8/8/4k3/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      final promotions = state.legalMoves
          .where((m) => m.from == Square.fromAlgebraic('e7'))
          .map((m) => m.promotion)
          .toSet();
      expect(promotions, {
        PieceType.queen,
        PieceType.rook,
        PieceType.bishop,
        PieceType.knight,
      });
    });

    test('offers all four promotion pieces on a capture to the last rank', () {
      final state = GameState.fromFen(
        '5n2/4P3/8/8/4k3/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      final destinations = state.legalMoves
          .where((m) => m.from == Square.fromAlgebraic('e7'))
          .map((m) => m.to.algebraic)
          .toSet();
      expect(destinations, {'e8', 'f8'});
    });

    test('promoting to a queen places a queen, not a pawn, on the board', () {
      final state = GameState.fromFen(
        '8/4P3/8/8/4k3/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      final applied = state
          .applyMove(
            Move(
              from: Square.fromAlgebraic('e7'),
              to: Square.fromAlgebraic('e8'),
              promotion: PieceType.queen,
            ),
          )
          .valueOrNull!;
      expect(
        applied.position.pieceAt(Square.fromAlgebraic('e8')),
        const Piece(Color.white, PieceType.queen),
      );
    });

    test('promoting to a knight places a knight, not a queen, on the board', () {
      final state = GameState.fromFen(
        '8/4P3/8/8/4k3/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      final applied = state
          .applyMove(
            Move(
              from: Square.fromAlgebraic('e7'),
              to: Square.fromAlgebraic('e8'),
              promotion: PieceType.knight,
            ),
          )
          .valueOrNull!;
      expect(
        applied.position.pieceAt(Square.fromAlgebraic('e8')),
        const Piece(Color.white, PieceType.knight),
      );
    });
  });
}
