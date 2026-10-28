import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';
import 'package:grand_chess/game/chess_bot.dart';

void main() {
  group('ChessBot', () {
    test('only returns a move from the engine legal-move list', () {
      final state = GameState.initial();
      final chosen = const ChessBot().chooseMove(
        state,
        level: BotLevel.tactical,
        random: Random(4),
      );

      expect(chosen, isNotNull);
      expect(state.legalMoves, contains(chosen));
    });

    test('easy mode returns a legal move from the current position', () {
      final state = GameState.initial();
      final chosen = const ChessBot().chooseMove(
        state,
        level: BotLevel.easy,
        random: Random(3),
      );

      expect(chosen, isNotNull);
      expect(state.legalMoves, contains(chosen));
    });

    test('returns null when the position has no legal moves', () {
      const fen = '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1';
      final state = GameState.fromFen(fen).valueOrNull!;

      expect(const ChessBot().chooseMove(state), isNull);
    });
  });
}
