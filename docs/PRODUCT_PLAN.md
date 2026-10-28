# Grand Chess — Product Plan

**Language / Bahasa:** [English](PRODUCT_PLAN.md) | [Bahasa Indonesia](PRODUCT_PLAN.id.md)

## 1. Purpose

Grand Chess is a beginner-friendly, cross-platform chess application built with Flutter and Dart. The first release focuses on a polished local game for two people using the same device.

## 2. Intended users

- People who want to play chess on a phone or desktop without creating an account.
- New chess players who benefit from clear move hints and readable game status.
- Developers learning Flutter who want a small, well-separated example project.

## 3. Current scope

The current app includes a chess rules engine, an immersive landscape game screen on supported mobile devices, tap-to-select/tap-to-move controls, an offline heuristic bot, undo/redo, FEN/PGN export text, selectable visual finishes, animated moves, and a perspective 3D board. Dragging empty board space rotates and tilts the view; it never triggers a chess move.

The separate 3D Arcade currently contains playable Cube Tic-Tac-Toe and Tower Builder. Chess rules covered by tests include legal move validation, check, checkmate, stalemate, castling, en passant, promotion, draw rules, and move notation. The renderer uses Flutter Canvas across supported Flutter targets.

## 4. User stories

- As a player, I can start a new local game and enter optional player names.
- As a player, I can see whose turn it is and which legal moves are available.
- As a player, I tap a piece to select it, then tap a legal destination; dragging the board controls the camera.
- As a player, I can rotate/tilt the 3D board, restore the default view, and choose board/piece finishes.
- As a player, I can undo/redo moves and copy the current FEN or move list as PGN text.
- As a player, I can play a local game against a lightweight offline bot or use the separate 3D Arcade.
- As a player, I can review the move list, flip the board, promote a pawn, and see the game result.
- As a developer, I can run the same rule tests and platform build checks in GitHub Actions.

## 5. Release requirements

A public release must meet all of these requirements:

1. Dart formatting, static analysis, and tests pass.
2. Release builds succeed for Android, Windows, Linux, macOS, iOS compilation, and web.
3. Board input, 3D rotation, move legality, dialogs, and responsive layouts are checked through automated tests.
4. The maintainer tests visuals and touch/mouse input on real devices.
5. The project owner chooses the source-code license and updates the GitHub repository description.
6. Store-bound packages are signed by the owner; a successful unsigned iOS compile is not an App Store release.

## 6. Roadmap

### Version 0.x — Local play

- [x] Implement the Dart chess engine and game state.
- [x] Add local two-player flow and move history.
- [x] Add automated engine and UI tests.
- [ ] Verify the 3D renderer through CI and hands-on device testing.
- [ ] Complete release metadata, licensing, and accessibility review.

### Version 1.x — Quality of life

- Save and resume local games.
- Export and import PGN games.
- Add configurable board materials, piece sets, camera presets, and color-blind-friendly highlights.
- Add sound, animation preferences, and keyboard/mouse accessibility checks.
- Add localized app UI and language selection.

### Later releases

- Improve the built-in bot or integrate Stockfish after cross-platform engine performance and packaging are evaluated.
- Add save/resume, clocks, animation settings and a fuller 3D model/material pipeline.
- Online play only after security, account, synchronization, and anti-cheat design are reviewed.
- Cloud sync only with clear privacy choices and reliable conflict handling.

## 7. Principles

Prefer simple code, explicit state, accessible labels, tests for chess rules, and no required account for local play. Avoid adding large dependencies when Flutter's built-in drawing or widgets solve the problem well.
