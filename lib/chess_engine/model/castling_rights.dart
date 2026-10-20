class CastlingRights {
  final bool whiteKingside;
  final bool whiteQueenside;
  final bool blackKingside;
  final bool blackQueenside;

  const CastlingRights({
    this.whiteKingside = false,
    this.whiteQueenside = false,
    this.blackKingside = false,
    this.blackQueenside = false,
  });

  static const none = CastlingRights();

  static const standard = CastlingRights(
    whiteKingside: true,
    whiteQueenside: true,
    blackKingside: true,
    blackQueenside: true,
  );

  CastlingRights copyWith({
    bool? whiteKingside,
    bool? whiteQueenside,
    bool? blackKingside,
    bool? blackQueenside,
  }) {
    return CastlingRights(
      whiteKingside: whiteKingside ?? this.whiteKingside,
      whiteQueenside: whiteQueenside ?? this.whiteQueenside,
      blackKingside: blackKingside ?? this.blackKingside,
      blackQueenside: blackQueenside ?? this.blackQueenside,
    );
  }

  String get fen {
    final buffer = StringBuffer();
    if (whiteKingside) buffer.write('K');
    if (whiteQueenside) buffer.write('Q');
    if (blackKingside) buffer.write('k');
    if (blackQueenside) buffer.write('q');
    return buffer.isEmpty ? '-' : buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is CastlingRights &&
      other.whiteKingside == whiteKingside &&
      other.whiteQueenside == whiteQueenside &&
      other.blackKingside == blackKingside &&
      other.blackQueenside == blackQueenside;

  @override
  int get hashCode => Object.hash(
    whiteKingside,
    whiteQueenside,
    blackKingside,
    blackQueenside,
  );

  @override
  String toString() => fen;
}
