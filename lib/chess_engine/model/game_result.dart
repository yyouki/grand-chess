import 'color.dart';

enum GameResult {
  ongoing,
  whiteWins,
  blackWins,
  draw;

  static GameResult fromCheckmate(Color sideDelivering) =>
      sideDelivering == Color.white
          ? GameResult.whiteWins
          : GameResult.blackWins;
}
