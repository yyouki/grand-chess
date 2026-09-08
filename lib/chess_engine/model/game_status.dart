enum GameStatus {
  ongoing,
  checkmate,
  stalemate,
  drawByFiftyMoveRule,
  drawByThreefoldRepetition,
  drawByInsufficientMaterial;

  bool get isGameOver => this != GameStatus.ongoing;

  bool get isDraw =>
      this == GameStatus.stalemate ||
      this == GameStatus.drawByFiftyMoveRule ||
      this == GameStatus.drawByThreefoldRepetition ||
      this == GameStatus.drawByInsufficientMaterial;
}
