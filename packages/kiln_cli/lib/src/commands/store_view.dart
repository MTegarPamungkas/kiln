/// One row in the `kiln store search` table.
final class StoreRow {
  const StoreRow({
    required this.id,
    required this.version,
    required this.tier,
    required this.category,
    required this.description,
    required this.status,
  });

  final String id;
  final String version;
  final String tier;
  final String category;
  final String description;

  /// `installed`, `update`, or `-`.
  final String status;
}

/// A titled block inside the info card.
final class StoreSection {
  const StoreSection(this.title, this.lines);

  final String title;
  final List<String> lines;
}

/// Structured `kiln store info` content.
final class StoreInfo {
  const StoreInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    this.fields = const <(String, String)>[],
    this.sections = const <StoreSection>[],
  });

  final String title;
  final String subtitle;
  final String description;
  final List<(String, String)> fields;
  final List<StoreSection> sections;
}

const List<String> _headers = <String>[
  'ID',
  'VERSION',
  'TIER',
  'CATEGORY',
  'STATUS',
  'DESCRIPTION',
];
const List<int> _widths = <int>[16, 8, 9, 11, 9, 44];

List<String> renderStoreSearch(List<StoreRow> rows, String term) {
  final lines = <String>[];
  if (rows.isEmpty) {
    lines
      ..add('No extensions matched "$term".')
      ..add('Try "kiln store search" to list everything.');
    return lines;
  }
  lines.add(
    term.isEmpty
        ? 'Available extensions (${rows.length})'
        : 'Found ${rows.length} ${rows.length == 1 ? 'extension' : 'extensions'} for "$term"',
  );
  lines.add('');
  lines.add(_border('+', '+', '+'));
  lines.add(_row(_headers));
  lines.add(_border('+', '+', '+'));
  for (final row in rows) {
    lines.add(
      _row(<String>[
        row.id,
        row.version,
        row.tier,
        row.category,
        row.status,
        row.description,
      ]),
    );
  }
  lines.add(_border('+', '+', '+'));
  lines.add('');
  lines.add('Tip: kiln store info <id>  ·  kiln store install <id>');
  return lines;
}

List<String> renderStoreInfo(StoreInfo info) {
  final lines = <String>[info.title, info.subtitle, '-' * 60];
  if (info.description.trim().isNotEmpty) {
    lines
      ..addAll(_wrap(info.description, 76))
      ..add('');
  }
  for (final field in info.fields) {
    final label = field.$1.padRight(14);
    final value = field.$2.trim().isEmpty ? '—' : field.$2;
    final wrapped = _wrap(value, 60);
    lines.add('$label${wrapped.first}');
    for (final extra in wrapped.skip(1)) {
      lines.add('${' ' * 14}$extra');
    }
  }
  for (final section in info.sections) {
    lines
      ..add('')
      ..add('${section.title}:');
    for (final line in section.lines) {
      lines.add('  $line');
    }
  }
  return lines;
}

String _row(List<String> cells) {
  final buffer = StringBuffer('|');
  for (var index = 0; index < cells.length; index++) {
    final cell = _truncate(cells[index], _widths[index]);
    buffer.write(' ${cell.padRight(_widths[index])} |');
  }
  return buffer.toString();
}

String _border(String left, String middle, String right) {
  return '$left${_widths.map((width) => '-' * (width + 2)).join(middle)}$right';
}

String _truncate(String value, int max) {
  final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= max) {
    return text;
  }
  return '${text.substring(0, max - 3)}...';
}

List<String> _wrap(String value, int width) {
  final words = value.replaceAll(RegExp(r'\s+'), ' ').trim().split(' ');
  final lines = <String>[];
  final buffer = StringBuffer();
  for (final word in words) {
    if (buffer.isEmpty) {
      buffer.write(word);
      continue;
    }
    if (buffer.length + 1 + word.length <= width) {
      buffer.write(' $word');
    } else {
      lines.add(buffer.toString());
      buffer
        ..clear()
        ..write(word);
    }
  }
  if (buffer.isNotEmpty) {
    lines.add(buffer.toString());
  }
  return lines.isEmpty ? const <String>[''] : lines;
}
