import '../model/piece_type.dart';
import '../model/square.dart';

class Move {
  final Square from;
  final Square to;
  final PieceType? promotion;
  final bool isCapture;
  final bool isEnPassant;
  final bool isCastleKingside;
  final bool isCastleQueenside;
  final bool isDoublePawnPush;

  const Move({
    required this.from,
    required this.to,
    this.promotion,
    this.isCapture = false,
    this.isEnPassant = false,
    this.isCastleKingside = false,
    this.isCastleQueenside = false,
    this.isDoublePawnPush = false,
  });

  bool get isPromotion => promotion != null;
  bool get isCastle => isCastleKingside || isCastleQueenside;

  /// Move identity is intentionally just (from, to, promotion) — the same
  /// triple UCI notation uses. Every other flag (isCapture, isEnPassant,
  /// isCastleKingside/Queenside, isDoublePawnPush) is fully derivable from
  /// (from, to, promotion) plus the position it is played in — a pawn
  /// moving diagonally onto an empty square can only be en passant, a king
  /// moving two squares can only be castling, and so on. Keeping equality
  /// limited to this triple means a caller who constructs a minimal
  /// `Move(from: ..., to: ...)` (e.g. from future UI input, without
  /// knowing which flags apply) still correctly matches the fully-flagged
  /// canonical [Move] produced by [MoveGenerator].
  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() {
    final promo = promotion != null ? '=${promotion!.fenLetter}' : '';
    return '${from.algebraic}${to.algebraic}$promo';
  }
}
