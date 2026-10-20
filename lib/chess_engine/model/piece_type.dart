enum PieceType {
  pawn,
  knight,
  bishop,
  rook,
  queen,
  king;

  String get fenLetter {
    switch (this) {
      case PieceType.pawn:
        return 'p';
      case PieceType.knight:
        return 'n';
      case PieceType.bishop:
        return 'b';
      case PieceType.rook:
        return 'r';
      case PieceType.queen:
        return 'q';
      case PieceType.king:
        return 'k';
    }
  }

  static PieceType fromFenLetter(String letter) {
    switch (letter.toLowerCase()) {
      case 'p':
        return PieceType.pawn;
      case 'n':
        return PieceType.knight;
      case 'b':
        return PieceType.bishop;
      case 'r':
        return PieceType.rook;
      case 'q':
        return PieceType.queen;
      case 'k':
        return PieceType.king;
      default:
        throw ArgumentError('Unknown piece letter: $letter');
    }
  }
}
