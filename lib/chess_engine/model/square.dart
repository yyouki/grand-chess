import '../../core/result.dart';
import '../errors/chess_engine_error.dart';

final RegExp _algebraicPattern = RegExp(r'^[a-h][1-8]$');

class Square {
  final int file;
  final int rank;

  const Square(this.file, this.rank);

  factory Square.fromIndex(int index) => Square(index % 8, index ~/ 8);

  /// Throws [ArgumentError] deterministically for any input that is not
  /// exactly one of `a1`..`h8` — wrong length, an out-of-range file letter,
  /// or an out-of-range rank digit all fail the same way, rather than only
  /// checking length and letting an out-of-range value silently produce an
  /// off-board [Square]. For untrusted input where a thrown exception is
  /// undesirable, use [tryFromAlgebraic] instead.
  factory Square.fromAlgebraic(String algebraic) {
    final result = tryFromAlgebraic(algebraic);
    if (result.isErr) {
      throw ArgumentError(result.errorOrNull!.message);
    }
    return result.valueOrNull!;
  }

  /// Same parsing as [fromAlgebraic], but returns an explicit
  /// [Result] instead of throwing — for callers handling genuinely
  /// untrusted input (future PGN/UCI/user-facing parsing), consistent with
  /// how the FEN codec reports invalid input elsewhere in this package.
  static Result<Square, InvalidSquareError> tryFromAlgebraic(String algebraic) {
    if (!_algebraicPattern.hasMatch(algebraic)) {
      return Result.err(InvalidSquareError(algebraic));
    }
    final file = algebraic.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(algebraic[1]) - 1;
    return Result.ok(Square(file, rank));
  }

  int get index => rank * 8 + file;

  bool get isOnBoard => file >= 0 && file < 8 && rank >= 0 && rank < 8;

  String get algebraic =>
      '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';

  Square offset(int fileDelta, int rankDelta) =>
      Square(file + fileDelta, rank + rankDelta);

  @override
  bool operator ==(Object other) =>
      other is Square && other.file == file && other.rank == rank;

  @override
  int get hashCode => Object.hash(file, rank);

  @override
  String toString() => algebraic;
}
