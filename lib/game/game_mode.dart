/// How the current game session is being played. Only [localTwoPlayer] is
/// functional in Phase 3 — [vsComputer] exists so the setup UI can show the
/// shape of the future option without pretending it works. Stockfish
/// integration is Phase 4, not implemented here.
enum GameMode { localTwoPlayer, vsComputer }
