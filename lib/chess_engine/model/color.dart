enum Color {
  white,
  black;

  Color get opponent => this == Color.white ? Color.black : Color.white;
}
