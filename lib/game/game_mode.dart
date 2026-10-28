/// How this chess session is played.
enum GameMode {
  /// Two people take turns on the same device.
  localTwoPlayer,

  /// White is controlled by the person; Black is controlled by the built-in
  /// offline legal-move bot.
  vsComputer,
}
