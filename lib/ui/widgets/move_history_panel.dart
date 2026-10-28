import 'package:flutter/material.dart';

import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/game_controller.dart';
import '../theme/app_theme.dart';

class MoveHistoryPanel extends StatefulWidget {
  const MoveHistoryPanel({super.key, required this.controller});

  final GameController controller;

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_HistoryRow> _buildRows() {
    final rows = <_HistoryRow>[];
    for (final record in widget.controller.gameState.moveHistory) {
      final isWhite = record.sideThatMoved == engine.Color.white;
      if (isWhite ||
          rows.isEmpty ||
          rows.last.number != record.fullmoveNumberBeforeMove) {
        rows.add(_HistoryRow(record.fullmoveNumberBeforeMove));
      }
      if (isWhite) {
        rows.last.white = record.san;
      } else {
        rows.last.black = record.san;
      }
    }
    return rows;
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final rows = _buildRows();
        _scrollToLatest();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moves',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text(
                        'No moves yet',
                        key: ValueKey('history-empty'),
                        style: TextStyle(color: AppTheme.mutedInk),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: rows.length,
                      itemBuilder: (context, index) =>
                          _HistoryRowView(row: rows[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryRow {
  _HistoryRow(this.number);

  final int number;
  String? white;
  String? black;
}

class _HistoryRowView extends StatelessWidget {
  const _HistoryRowView({required this.row});

  final _HistoryRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${row.number}.',
              style: const TextStyle(color: AppTheme.mutedInk),
            ),
          ),
          Expanded(
            child: Text(
              row.white ?? '...',
              key: ValueKey('move-${row.number}-white'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.black ?? '',
              key: ValueKey('move-${row.number}-black'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
