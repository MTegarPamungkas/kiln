import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import '../log_exporter.dart';
import '../log_formatter.dart';
import '../memory_log_sink.dart';

/// Shows the records currently held by a [MemoryLogSink].
///
/// The page is a diagnostics tool: in a production flavor it renders a notice
/// instead of the buffer, so log content never reaches a shipped screen. The
/// default is production so forgetting the flavor cannot leak logs; pass the
/// application flavor from the caller.
final class DebugLogPage extends StatefulWidget {
  const DebugLogPage({
    super.key,
    required this.sink,
    this.flavor = AppFlavor.production,
    this.exporter,
  });

  final MemoryLogSink sink;
  final AppFlavor flavor;
  final LogExporter? exporter;

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

final class _DebugLogPageState extends State<DebugLogPage> {
  bool get _visible => !widget.flavor.isProduction;

  void _refresh() => setState(() {});

  void _clear() {
    widget.sink.clear();
    setState(() {});
  }

  Future<void> _export() async {
    final exporter = widget.exporter;
    if (exporter == null) {
      return;
    }
    final report = await exporter.export();
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ekspor log'),
        content: SingleChildScrollView(child: SelectableText(report)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.sink.records.reversed.toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log'),
        actions: _visible
            ? <Widget>[
                if (widget.exporter != null)
                  IconButton(
                    onPressed: _export,
                    tooltip: 'Ekspor',
                    icon: const Icon(Icons.ios_share),
                  ),
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: _clear,
                  tooltip: 'Bersihkan',
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : null,
      ),
      body: _visible
          ? _buildBody(records)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Log hanya tersedia di flavor non-production.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  Widget _buildBody(List<LogRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('Belum ada log.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildTile(records[index]),
    );
  }

  Widget _buildTile(LogRecord record) {
    final theme = Theme.of(context);
    final data = record.data;
    return ListTile(
      dense: true,
      leading: _LevelBadge(level: record.level),
      title: Text(record.message),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LogFormatter.timestamp(record.timestamp),
            style: theme.textTheme.bodySmall,
          ),
          if (record.error != null)
            Text(
              '${record.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (data != null && data.isNotEmpty)
            Text('$data', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

final class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final LogLevel level;

  Color get _color {
    return switch (level) {
      LogLevel.trace => Colors.blueGrey,
      LogLevel.debug => Colors.blue,
      LogLevel.info => Colors.green,
      LogLevel.warning => Colors.orange,
      LogLevel.error => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        LogFormatter.levelLabel(level),
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
