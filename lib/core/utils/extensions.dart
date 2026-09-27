import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// Notch, status bar and home indicator — what a full-bleed layout has to
  /// keep clear of.
  EdgeInsets get safeInsets => MediaQuery.viewPaddingOf(this);

  /// How much of the screen the keyboard is covering right now.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;
  bool get isKeyboardOpen => keyboardInset > 0;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// The 600dp Material breakpoint, measured on the short side so it survives
  /// rotation.
  bool get isTablet => MediaQuery.sizeOf(this).shortestSide >= 600;

  /// Drops focus and closes the keyboard.
  void unfocus() => FocusScope.of(this).unfocus();
}

extension FormX on GlobalKey<FormState> {
  /// Runs every validator under the form and reports whether they all passed:
  /// `if (_formKey.isValid) submit();`.
  ///
  /// False when the form is not mounted, so a submit can never read a
  /// validation that did not run as a pass.
  bool get isValid => currentState?.validate() ?? false;
}

extension StringX on String {
  bool get isValidEmail =>
      RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(this);

  bool? isValidUrl() {
    if (isEmpty) return null;
    final uri = Uri.tryParse(this);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Empty once whitespace is discounted — the check `isEmpty` misses on '  '.
  bool get isBlank => trim().isEmpty;

  /// This string, or null when blank — for API fields better omitted than ''.
  String? get nullIfBlank => isBlank ? null : this;

  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Capitalises every word: 'ana maria' -> 'Ana Maria'.
  String get capitalizeWords =>
      split(' ').map((word) => word.isEmpty ? word : word.capitalize).join(' ');

  /// Up to two initials for an avatar: 'Ana Maria Silva' -> 'AS'.
  String get initials {
    final words = trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    if (words.length == 1) {
      final word = words.first;
      return (word.length == 1 ? word : word.substring(0, 2)).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  /// Cuts to [max] characters, ellipsis included, so the result never exceeds
  /// [max]. Returns the string untouched when it already fits.
  String truncate(int max, {String ellipsis = '…'}) {
    if (length <= max) return this;
    if (max <= ellipsis.length) return substring(0, max);
    return '${substring(0, max - ellipsis.length).trimRight()}$ellipsis';
  }

  bool get isNumeric => num.tryParse(this) != null;

  String get digitsOnly => replaceAll(RegExp(r'\D'), '');

  /// Strips accents: 'São Paulo' -> 'Sao Paulo'.
  String get withoutDiacritics {
    final buffer = StringBuffer();
    for (final char in split('')) {
      final index = _accented.indexOf(char);
      buffer.write(index == -1 ? char : _unaccented[index]);
    }
    return buffer.toString();
  }

  /// Lower case and accent-free, so 'sao' matches 'São'.
  String get searchKey => withoutDiacritics.toLowerCase().trim();

  /// True when [query] appears in this string, ignoring case and accents.
  bool matchesSearch(String query) => searchKey.contains(query.searchKey);

  int? get toIntOrNull => int.tryParse(this);
  double? get toDoubleOrNull => double.tryParse(this);

  /// Parses `#RGB`, `#RRGGBB` or `#AARRGGBB`; null when it is not a hex color.
  Color? toColor() {
    var hexColor = replaceAll('#', '').trim();
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((c) => '$c$c').join();
    }
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length != 8) return null;

    final value = int.tryParse(hexColor, radix: 16);
    return value == null ? null : Color(value);
  }

  /// Parses this string as a date; returns null when no known format matches.
  DateTime? toDateTime() {
    final formats = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'd/M/yyyy',
      'M/d/yyyy',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parseStrict(this);
      } catch (_) {}
    }

    final parts = split(RegExp(r'[/\-]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);

      if (a != null && b != null && c != null) {
        // c is year if > 31, assume d/M/yyyy
        if (c > 31) return DateTime(c, b, a);
        // a is year if > 31, assume yyyy/M/d
        if (a > 31) return DateTime(a, b, c);
      }
    }
    return null;
  }
}

extension NullableStringX on String? {
  /// Null, empty, or whitespace — the check you actually want on an API field.
  bool get isNullOrBlank => this?.trim().isEmpty ?? true;

  bool get isNotNullOrBlank => !isNullOrBlank;

  /// This string, or '' when it is null — for feeding a Text widget.
  String get orEmpty => this ?? '';
}

extension DateTimeX on DateTime {
  String get formattedDate =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  String get formattedDateTime => '$formattedDate $formattedTime';

  /// yyyy-MM-ddTHH:mm:ss.mmmZ, converted to UTC.
  String get formatedDateTimeToDatabase => toUtc().toIso8601String();

  // yyyy-MM-dd
  String get formattedDateToDatabase =>
      "${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

  /// Formats with any [DateFormat] pattern: `format('EEE, d MMM')`.
  String format(String pattern, [String? locale]) =>
      DateFormat(pattern, locale).format(this);

  bool get isToday => isSameDay(DateTime.now());

  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  /// Midnight on this date — the value to compare or group days by.
  DateTime get startOfDay => DateTime(year, month, day);

  /// The last instant of this date, for an inclusive range end.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfMonth => DateTime(year, month);

  /// Day 0 of the next month is the last day of this one.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Whole years since this date — an age, or how long ago something happened.
  int get yearsSince {
    final now = DateTime.now();
    final had = now.month > month || (now.month == month && now.day >= day);
    return now.year - year - (had ? 0 : 1);
  }

  TimeOfDay get toTimeOfDay => TimeOfDay(hour: hour, minute: minute);

  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }
}

extension TimeOfDayX on TimeOfDay {
  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Minutes since midnight — the number to sort or compare two times by.
  int get minutesOfDay => hour * 60 + minute;

  bool isBefore(TimeOfDay other) => minutesOfDay < other.minutesOfDay;
  bool isAfter(TimeOfDay other) => minutesOfDay > other.minutesOfDay;

  /// This time of day on [date] — merges a separate date and time field.
  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);
}

extension DurationX on Duration {
  /// `m:ss`, or `h:mm:ss` once it passes an hour — media and timer style.
  String get formatted {
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) {
      final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
      return '$inHours:$minutes:$seconds';
    }
    return '${inMinutes.remainder(60)}:$seconds';
  }
}

extension NumX on num {
  String formatCurrency(String code) {
    return NumberFormat.simpleCurrency(name: code).format(this);
  }

  /// Fixed decimals with locale grouping: `1234.5.formatDecimal()` -> '1,234.50'.
  String formatDecimal({int decimals = 2}) =>
      NumberFormat.decimalPatternDigits(decimalDigits: decimals).format(this);

  /// Short form for counters and charts: 1200 -> '1.2K'.
  String get formatCompact => NumberFormat.compact().format(this);

  /// Formats as a percentage. Give it a ratio, not a number out of 100:
  /// `0.42.formatPercent()` -> '42%'.
  String formatPercent({int decimals = 0}) =>
      '${(this * 100).toStringAsFixed(decimals)}%';
}

extension NullableListX<T> on List<T>? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

// Accented characters and their plain equivalents, index for index.
const _accented = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÑñÇç';
const _unaccented = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc';
