// Regression suite for chess_engine.
//
// Convention: every time a real bug is found, add a focused test here that
// reproduces the exact failing scenario, with a comment naming what broke.
// Never delete an entry once added — that is the entire point of a
// regression suite. Full-feature coverage for these areas lives in their
// natural test files (draw_rules_test.dart, move_application_test.dart,
// etc.); the tests below are intentionally minimal, targeting only the
// exact scenario that was previously wrong.

import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  group('Regressions', () {
    test(
      'GameState.fromFen correctly derives a non-ongoing result for an '
      'already-checkmated position (previously hardcoded to ongoing)',
      () {
        final state = GameState.fromFen(
          'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
        ).valueOrNull!;
        expect(state.status, GameStatus.checkmate);
        expect(
          state.result,
          GameResult.blackWins,
          reason:
              'fromFen/initial once hardcoded result to GameResult.ongoing '
              'regardless of the computed status',
        );
      },
    );

    test(
      'Move equality ignores derived metadata flags, matching a minimal '
      'caller-constructed Move against the fully-flagged generator Move '
      '(previously, mismatched flags made a legal move look illegal)',
      () {
        final state = GameState.fromFen(
          'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
        ).valueOrNull!;
        // Deliberately minimal: no isEnPassant/isCapture flags set, exactly
        // as a future UI layer would construct it from a drag-and-drop.
        final minimalMove = Move(
          from: Square.fromAlgebraic('e5'),
          to: Square.fromAlgebraic('d6'),
        );
        final result = state.applyMove(minimalMove);
        expect(result.isOk, isTrue);
        expect(
          result.valueOrNull!.position.pieceAt(Square.fromAlgebraic('d5')),
          isNull,
        );
      },
    );

    test(
      'Repetition identity does not treat an illegal (pinned) en passant '
      'capture as available (previously any geometrically-positioned pawn '
      'counted, legal or not)',
      () {
        const rules = GameRules();
        const codec = FenCodec();
        // White king e5, white pawn d5, black rook a5, black pawn c5 (just
        // double-pushed, en passant target c6). Capturing en passant would
        // remove both d5 and c5 from the rank, exposing the king to the
        // rook — so it is geometrically available but illegal.
        final withPinnedEp =
            codec.parse('4k3/8/8/r1pPK3/8/8/8/8 w - c6 0 1').valueOrNull!;
        final withoutEp =
            codec.parse('4k3/8/8/r1pPK3/8/8/8/8 w - - 0 1').valueOrNull!;

        // If the illegal en passant target were (wrongly) treated as
        // relevant, these three would NOT all share a repetition key, and
        // this would fail to reach threefold repetition.
        final status = rules.determineStatus(
          withoutEp,
          [withoutEp, withPinnedEp, withoutEp],
        );
        expect(status, GameStatus.drawByThreefoldRepetition);
      },
    );

    test(
      'Conversely, a genuinely legal en passant target DOES distinguish '
      'repetition identity — the fix for the pinned case above must not '
      'over-correct into ignoring en passant entirely',
      () {
        const rules = GameRules();
        const codec = FenCodec();
        final withLegalEp = codec
            .parse('rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3')
            .valueOrNull!;
        final withoutEp = codec
            .parse('rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3')
            .valueOrNull!;

        // Only 2 of the 3 entries share a key with withoutEp — below the
        // threefold threshold — because the legal en passant option is a
        // real, rules-relevant difference between the positions.
        final status = rules.determineStatus(
          withoutEp,
          [withoutEp, withLegalEp, withoutEp],
        );
        expect(status, isNot(GameStatus.drawByThreefoldRepetition));
      },
    );
    test(
      'positionHistory and moveHistory reject external mutation attempts '
      '(a final List field only prevents reassignment, not in-place '
      'mutation of the list it points to — the fields are now wrapped '
      'with List.unmodifiable)',
      () {
        final state = GameState.initial();
        expect(
          () => state.positionHistory.add(state.position),
          throwsUnsupportedError,
        );
        expect(() => state.moveHistory.clear(), throwsUnsupportedError);
      },
    );

    group('Castling requires the actual rook (not just the recorded right)', () {
      test('missing kingside rook: right recorded, square empty', () {
        final state =
            GameState.fromFen('4k3/8/8/8/8/8/8/4K3 w K - 0 1').valueOrNull!;
        expect(
          state.legalMoves.any((m) => m.to == Square.fromAlgebraic('g1')),
          isFalse,
        );
      });

      test('missing queenside rook: right recorded, square empty', () {
        final state =
            GameState.fromFen('4k3/8/8/8/8/8/8/4K3 w Q - 0 1').valueOrNull!;
        expect(
          state.legalMoves.any((m) => m.to == Square.fromAlgebraic('c1')),
          isFalse,
        );
      });

      test('non-rook piece on the rook square (bishop)', () {
        final state = GameState.fromFen(
          '4k3/8/8/8/8/8/8/4K2B w K - 0 1',
        ).valueOrNull!;
        expect(
          state.legalMoves.any((m) => m.to == Square.fromAlgebraic('g1')),
          isFalse,
        );
      });

      test('wrong-color rook on the rook square', () {
        // A black rook on h1 also happens to check the white king along
        // the open rank — castling would be blocked for that reason too,
        // but the rook-presence/color check must independently reject it
        // as well (that is what this fix targets, not the check itself).
        final state = GameState.fromFen(
          '4k3/8/8/8/8/8/8/4K2r w K - 0 1',
        ).valueOrNull!;
        expect(
          state.legalMoves.any((m) => m.to == Square.fromAlgebraic('g1')),
          isFalse,
        );
      });

      test('valid castling on both sides still works after the fix', () {
        final state = GameState.fromFen(
          'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
        ).valueOrNull!;
        final destinations = state.legalMoves
            .where((m) => m.from == Square.fromAlgebraic('e1'))
            .map((m) => m.to.algebraic)
            .toSet();
        expect(destinations, containsAll({'c1', 'g1'}));
      });
    });

    test(
      'capturing the opposing king is never offered as a legal move, even '
      'from a directly-loaded position where it looks pseudo-legally '
      'available (FEN semantic validation deliberately does not check '
      '"is the side not to move currently in check")',
      () {
        final state = GameState.fromFen(
          'k7/8/8/8/8/8/8/R3K3 w - - 0 1',
        ).valueOrNull!;
        expect(
          state.legalMoves.any((m) => m.to == Square.fromAlgebraic('a8')),
          isFalse,
        );
      },
    );

    group('En passant requires the actual capturable pawn, not just a '
        'matching target square', () {
      test('EP target recorded, but the capture square is empty', () {
        // White pawn d5, en passant target e6, but e5 (the square the
        // capture would remove a pawn from) is empty -- stale FEN state.
        final state = GameState.fromFen(
          '4k3/8/8/3P4/8/8/8/4K3 w - e6 0 1',
        ).valueOrNull!;
        expect(
          state.legalMoves.any((m) =>
              m.from == Square.fromAlgebraic('d5') && m.isEnPassant),
          isFalse,
        );
      });

      test('EP target recorded, but a non-pawn piece sits on the capture square', () {
        final state = GameState.fromFen(
          '4k3/8/8/3Pn3/8/8/8/4K3 w - e6 0 1',
        ).valueOrNull!;
        expect(
          state.legalMoves.any((m) =>
              m.from == Square.fromAlgebraic('d5') && m.isEnPassant),
          isFalse,
        );
      });

      test('EP target recorded, but the piece on the capture square is the same color', () {
        final state = GameState.fromFen(
          '4k3/8/8/3PP3/8/8/8/4K3 w - e6 0 1',
        ).valueOrNull!;
        expect(
          state.legalMoves.any((m) =>
              m.from == Square.fromAlgebraic('d5') && m.isEnPassant),
          isFalse,
        );
      });
    });
  });
}
