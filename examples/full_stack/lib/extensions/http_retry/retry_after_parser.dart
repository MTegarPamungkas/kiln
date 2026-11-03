/// Parses the Retry-After header in seconds or HTTP-date form.
final class RetryAfterParser {
  const RetryAfterParser();

  static const Map<String, int> _months = <String, int>{
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  Duration? parse(String? value, {required DateTime now}) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final seconds = int.tryParse(trimmed);
    if (seconds != null) {
      return Duration(seconds: seconds < 0 ? 0 : seconds);
    }
    final date = _parseHttpDate(trimmed);
    if (date == null) {
      return null;
    }
    final difference = date.difference(now.toUtc());
    return difference.isNegative ? Duration.zero : difference;
  }

  DateTime? _parseHttpDate(String value) {
    final match = RegExp(
      r'^(?:[A-Za-z]{3},\s*)?(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
      r'(\d{2}):(\d{2}):(\d{2})\s+GMT$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final month = _months[match.group(2)!];
    if (month == null) {
      return null;
    }
    try {
      return DateTime.utc(
        int.parse(match.group(3)!),
        month,
        int.parse(match.group(1)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        int.parse(match.group(6)!),
      );
    } catch (_) {
      return null;
    }
  }
}
