# Grand Chess — Technical Decisions

**Language / Bahasa:** [English](Grand-Chess-ADR.md) | [Bahasa Indonesia](Grand-Chess-ADR.id.md)

An ADR (Architecture Decision Record) explains why the project uses a particular technical approach. This file is intentionally written in plain language so new contributors can understand the trade-offs.

## ADR-001: Flutter and Dart

**Decision:** Use Flutter and Dart for the app and chess engine.

**Why:** One shared codebase can target mobile, desktop, and web. Dart also makes it possible to test chess rules without rendering a screen.

**Trade-off:** Native platform folders and signing still require platform-specific tools. Flutter support does not mean every target is built or signed automatically.

## ADR-002: Keep the chess engine independent from UI

**Decision:** Chess rules, board position, and legal move validation belong in the engine/domain folders, not in screen widgets.

**Why:** Rules can be tested quickly, reused by future features, and reviewed without depending on layout code.

**Trade-off:** UI actions must pass through the game controller instead of changing board state directly.

## ADR-003: Render the 3D board with Flutter Canvas

**Decision:** Build a custom perspective renderer using projected 3D geometry and Canvas drawing.

**Why:** The app needs a board and pieces with visible height, depth, material shading, and a camera that can rotate through 360 degrees. A custom renderer avoids a mandatory native 3D dependency and keeps the same implementation available to Flutter's mobile, desktop, and web targets.

**Trade-off:** This is a software-rendered scene, not a full physically based 3D engine. Advanced shadows, realistic reflections, imported 3D models, and performance on older devices need separate evaluation.

## ADR-004: Use one game controller

**Decision:** A game controller owns the current position, selection, legal targets, move history, and game result.

**Why:** The board, status bar, dialogs, and history should display the same game state. Tests can also exercise the controller without clicking through the whole app.

**Trade-off:** The controller must notify the UI when its state changes and be disposed when its screen is removed.

## ADR-005: Test builds through GitHub Actions

**Decision:** Use GitHub Actions to format, analyze, test, and build every supported target.

**Why:** Maintainers can verify changes without requiring every contributor to own every operating system.

**Trade-off:** CI compilation is not a substitute for real-device tests, signing keys, store review, or app-store submission.

## ADR-006: Do not add accounts or online services to local play

**Decision:** The first release remains local and does not require an account or backend.

**Why:** This keeps setup simple and avoids collecting personal data before it is needed.

**Trade-off:** Cloud sync, matchmaking, and account-based features require a separate privacy and security design before implementation.
