import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../chess_engine/chess_engine.dart' as engine;

/// Standard over-the-board time controls plus an untimed option.
enum ChessTimeControl {
  untimed(Duration.zero, Duration.zero, 'Unlimited'),
  bullet1(Duration(seconds: 60), Duration.zero, '1 + 0 · Bullet'),
  blitz3(Duration(minutes: 3), Duration(seconds: 2), '3 + 2 · Blitz'),
  blitz5(Duration(minutes: 5), Duration(seconds: 3), '5 + 3 · Blitz'),
  rapid10(Duration(minutes: 10), Duration.zero, '10 + 0 · Rapid'),
  rapid15(Duration(minutes: 15), Duration(seconds: 10), '15 + 10 · Rapid');

  const ChessTimeControl(this.initialTime, this.increment, this.label);

  final Duration initialTime;
  final Duration increment;
  final String label;

  bool get isTimed => initialTime > Duration.zero;
}

class _ClockSnapshot {
  const _ClockSnapshot({
    required this.white,
    required this.black,
    required this.activeSide,
  });

  final Duration white;
  final Duration black;
  final engine.Color activeSide;
}

/// Cross-platform chess clock. It stores a clock snapshot per move so
/// takebacks and redo restore the same times instead of granting extra time.
class ChessClockController extends ChangeNotifier {
  ChessClockController({required this.timeControl}) {
    _resetValues();
  }

  final ChessTimeControl timeControl;
  Timer? _timer;
  DateTime? _lastTickAt;
  late Duration _whiteRemaining;
  late Duration _blackRemaining;
  engine.Color _activeSide = engine.Color.white;
  engine.Color? _flaggedSide;
  bool _isRunning = false;
  int _currentPly = 0;
  final Map<int, _ClockSnapshot> _snapshots = {};

  bool get isEnabled => timeControl.isTimed;
  bool get isRunning => _isRunning;
  engine.Color get activeSide => _activeSide;
  engine.Color? get flaggedSide => _flaggedSide;
  Duration get whiteRemaining => _whiteRemaining;
  Duration get blackRemaining => _blackRemaining;
  int get currentPly => _currentPly;

  Duration remainingFor(engine.Color side) =>
      side == engine.Color.white ? _whiteRemaining : _blackRemaining;

  /// Starts the current side's clock. Calling start repeatedly is harmless.
  void start() {
    if (!isEnabled || _isRunning || _flaggedSide != null) return;
    _isRunning = true;
    _lastTickAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _pulse());
    notifyListeners();
  }

  /// Pauses both clocks, accounting for elapsed time first.
  void pause() {
    if (!_isRunning) return;
    _pulse();
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _lastTickAt = null;
    notifyListeners();
  }

  /// Reset to the selected time control and begin again with White to move.
  void resetAndStart() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _lastTickAt = null;
    _resetValues();
    _snapshots
      ..clear()
      ..[0] = _capture();
    start();
  }

  void _resetValues() {
    _whiteRemaining = timeControl.initialTime;
    _blackRemaining = timeControl.initialTime;
    _activeSide = engine.Color.white;
    _flaggedSide = null;
    _currentPly = 0;
  }

  /// Called when a legal chess move has just been committed. Increment is
  /// added to the player who moved, and the other clock becomes active.
  void completeMove({
    required int newPly,
    required engine.Color sideThatMoved,
    required engine.Color sideToMove,
  }) {
    if (newPly <= _currentPly) {
      setActiveSide(sideToMove);
      return;
    }

    _pulse();
    if (_flaggedSide != null) return;

    // Record the exact time before the move, for a future takeback.
    _snapshots[_currentPly] = _capture();
    // A new move after a takeback creates a new branch of the game.
    _snapshots.removeWhere((ply, _) => ply > _currentPly);

    if (sideThatMoved == engine.Color.white) {
      _whiteRemaining += timeControl.increment;
    } else {
      _blackRemaining += timeControl.increment;
    }
    _activeSide = sideToMove;
    _currentPly = newPly;
    _snapshots[newPly] = _capture();
    _lastTickAt = DateTime.now();
    notifyListeners();
  }

  /// Restores the clock snapshot corresponding to [ply] after undo/redo.
  /// If a snapshot is not available, it preserves remaining time and aligns
  /// the active clock with the chess position.
  void restoreToPly(int ply, engine.Color sideToMove) {
    _pulse();
    if (_flaggedSide != null) return;

    final snapshot = _snapshots[ply];
    if (snapshot != null) {
      _whiteRemaining = snapshot.white;
      _blackRemaining = snapshot.black;
      _activeSide = snapshot.activeSide;
    } else {
      _activeSide = sideToMove;
    }
    _currentPly = ply;
    _lastTickAt = _isRunning ? DateTime.now() : null;
    notifyListeners();
  }

  /// Allows deterministic clock tests and is also the accounting primitive
  /// used by the periodic timer.
  @visibleForTesting
  void elapse(Duration duration) {
    _lastTickAt = _isRunning ? DateTime.now() : null;
    _consumeElapsed(duration);
  }

  void setActiveSide(engine.Color side) {
    if (_flaggedSide != null || _activeSide == side) return;
    _pulse();
    if (_flaggedSide != null) return;
    _activeSide = side;
    _lastTickAt = _isRunning ? DateTime.now() : null;
    notifyListeners();
  }

  void _pulse() {
    if (!_isRunning || _flaggedSide != null) return;
    final last = _lastTickAt;
    final now = DateTime.now();
    _lastTickAt = now;
    if (last == null) return;
    _consumeElapsed(now.difference(last));
  }

  void _consumeElapsed(Duration elapsed) {
    if (!isEnabled || !_isRunning || _flaggedSide != null) return;
    if (elapsed <= Duration.zero) return;

    final before = _displaySeconds(remainingFor(_activeSide));
    final current = remainingFor(_activeSide);
    final nextMs = math.max(0, current.inMilliseconds - elapsed.inMilliseconds);
    final next = Duration(milliseconds: nextMs);
    if (_activeSide == engine.Color.white) {
      _whiteRemaining = next;
    } else {
      _blackRemaining = next;
    }

    if (next == Duration.zero) {
      _flaggedSide = _activeSide;
      _isRunning = false;
      _timer?.cancel();
      _timer = null;
      _lastTickAt = null;
      notifyListeners();
      return;
    }

    if (_displaySeconds(next) != before) {
      notifyListeners();
    }
  }

  int _displaySeconds(Duration value) => (value.inMilliseconds / 1000).ceil();

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  static String format(Duration duration) {
    final totalSeconds = (duration.inMilliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final hours = minutes ~/ 60;
    final remainderMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${remainderMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
