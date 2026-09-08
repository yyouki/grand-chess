import '../board/position.dart';
import '../model/piece_type.dart';
import '../move/move.dart';
import '../rules/game_rules.dart';
import '../rules/move_generator.dart';

class SanGenerator {
  const SanGenerator({
    this.moveGenerator = const MoveGenerator(),
    this.gameRules = const GameRules(),
  });

  final MoveGenerator moveGenerator;
  final GameRules gameRules;

  /// Generates SAN for [move] played from [before]. Check/checkmate suffix
  /// is determined from the resulting position.
  String generate(Position before, Move move) {
    final after = before.applyMove(move);

    if (move.isCastle) {
      final base = move.isCastleKingside ? 'O-O' : 'O-O-O';
      return base + _checkSuffix(after);
    }

    final piece = before.pieceAt(move.from)!;
    final buffer = StringBuffer();

    if (piece.type == PieceType.pawn) {
      if (move.isCapture) {
        buffer.write(String.fromCharCode('a'.codeUnitAt(0) + move.from.file));
        buffer.write('x');
      }
      buffer.write(move.to.algebraic);
      if (move.promotion != null) {
        buffer.write('=');
        buffer.write(move.promotion!.fenLetter.toUpperCase());
      }
    } else {
      buffer.write(_pieceLetter(piece.type));
      buffer.write(_disambiguation(before, move, piece.type));
      if (move.isCapture) buffer.write('x');
      buffer.write(move.to.algebraic);
    }

    buffer.write(_checkSuffix(after));
    return buffer.toString();
  }

  String _pieceLetter(PieceType type) => type.fenLetter.toUpperCase();

  /// Implements standard SAN disambiguation: prefer origin file; if the
  /// file alone does not resolve the ambiguity, fall back to origin rank;
  /// if neither alone resolves it, use the full origin square.
  String _disambiguation(Position before, Move move, PieceType type) {
    final piece = before.pieceAt(move.from)!;
    final ambiguous = moveGenerator
        .generateLegalMoves(before)
        .where(
          (m) =>
              m.to == move.to &&
              m.from != move.from &&
              before.pieceAt(m.from)?.type == type &&
              before.pieceAt(m.from)?.color == piece.color,
        )
        .toList();

    if (ambiguous.isEmpty) return '';

    final sameFile = ambiguous.any((m) => m.from.file == move.from.file);
    final sameRank = ambiguous.any((m) => m.from.rank == move.from.rank);

    if (!sameFile) {
      return String.fromCharCode('a'.codeUnitAt(0) + move.from.file);
    }
    if (!sameRank) {
      return '${move.from.rank + 1}';
    }
    return move.from.algebraic;
  }

  String _checkSuffix(Position after) {
    if (!gameRules.isInCheck(after)) return '';
    final hasReply = moveGenerator.generateLegalMoves(after).isNotEmpty;
    return hasReply ? '+' : '#';
  }
}
