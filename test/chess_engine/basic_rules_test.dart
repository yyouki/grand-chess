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
  group('Initial position', () {
    test('has 20 legal moves for White', () {
      expect(GameState.initial().legalMoves.length, 20);
    });

    test('places pieces on the correct starting squares', () {
      final position = Position.initial();
      expect(
        position.pieceAt(Square.fromAlgebraic('e1')),
        const Piece(Color.white, PieceType.king),
      );
      expect(
        position.pieceAt(Square.fromAlgebraic('e8')),
        const Piece(Color.black, PieceType.king),
      );
      expect(
        position.pieceAt(Square.fromAlgebraic('a1')),
        const Piece(Color.white, PieceType.rook),
      );
      expect(position.pieceAt(Square.fromAlgebraic('e4')), isNull);
    });

    test('White moves first', () {
      expect(Position.initial().sideToMove, Color.white);
    });
  });

  group('Pawn movement', () {
    test('can push one or two squares from the starting rank', () {
      final state = GameState.initial();
      expect(destinationsFrom(state, 'e2'), {'e3', 'e4'});
    });

    test('cannot push through a blocking piece', () {
      final state = GameState.fromFen(
        'rnbqkbnr/pppp1ppp/8/8/4p3/4P3/PPPP1PPP/RNBQKBNR w KQkq - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e3'), isEmpty);
    });

    test('captures diagonally', () {
      final state = GameState.fromFen(
        'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e4'), {'d5', 'e5'});
    });
  });

  group('Knight movement', () {
    test('has the expected 2 opening moves each from b1 and g1', () {
      final state = GameState.initial();
      expect(destinationsFrom(state, 'b1'), {'a3', 'c3'});
      expect(destinationsFrom(state, 'g1'), {'f3', 'h3'});
    });

    test('jumps over occupied squares and cannot land on its own piece', () {
      final state = GameState.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/2N5/PPPPPPPP/R1BQKBNR w KQkq - 2 2',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'c3'), {'a4', 'b1', 'b5', 'd5', 'e4'});
    });
  });

  group('Sliding pieces', () {
    test('bishop is blocked by its own pawns at the start', () {
      final state = GameState.initial();
      expect(destinationsFrom(state, 'c1'), isEmpty);
    });

    test('rook slides until blocked and can capture the blocker', () {
      final state = GameState.fromFen(
        '4k3/8/8/p7/8/8/8/R3K3 w Q - 0 1',
      ).valueOrNull!;
      final rookMoves = destinationsFrom(state, 'a1');
      expect(rookMoves, containsAll({'a2', 'a3', 'a4', 'a5'}));
      expect(rookMoves, isNot(contains('a6')));
    });

    test('queen combines rook and bishop movement', () {
      final state = GameState.fromFen(
        '4k3/8/8/8/8/8/8/3QK3 w - - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'd1'), {
        'a1', 'b1', 'c1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8',
        'a4', 'b3', 'c2', 'e2', 'f3', 'g4', 'h5',
      });
    });
  });

  group('King movement', () {
    test('moves one square in any direction when not blocked', () {
      final state = GameState.fromFen(
        '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e1'), {'d1', 'd2', 'e2', 'f1', 'f2'});
    });

    test('cannot move next to the enemy king', () {
      final state = GameState.fromFen(
        '8/8/8/8/8/4k3/8/4K3 w - - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e1'), {'d1', 'f1'});
    });
  });
}
