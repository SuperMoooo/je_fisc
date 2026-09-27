import 'package:flutter/services.dart';

import '../../../core/security/validation_service.dart';

/// Separators the money formatter inserts. Both [MoneyInputFormatter] and
/// [AppInputFormat.unformat] read them, so switching an app to another locale
/// is a two-line edit here.
const String moneyGroupSeparator = ',';
const String moneyDecimalSeparator = '.';

/// What a field holds — the one knob that decides how it behaves.
///
/// A format resolves to a keyboard, the [TextInputFormatter]s that keep junk
/// out while the user types, autofill hints and the [InputType] the value is
/// validated against. Set it once and the rest follows:
///
///   AppInput(label: 'Amount', format: AppInputFormat.money)
///
/// Everything it decides is a plain getter, so a hand-rolled [TextField] can
/// borrow the same behaviour without going through `AppInput`.
enum AppInputFormat {
  /// Free text, unfiltered.
  text,

  /// Free text over several lines — a notes or description box.
  multiline,

  /// A person's name: word capitalisation and name autofill.
  personName,

  /// An email address: lower-cased, no spaces.
  email,

  /// A secret: obscured by default, password autofill.
  password,

  /// A handle: letters, digits, `-` and `_` only.
  username,

  /// A link, no spaces.
  url,

  /// A phone number: digits and the punctuation phone numbers use.
  phone,

  /// A whole number.
  integer,

  /// A number with up to two decimal places.
  decimal,

  /// An amount: decimals plus thousands grouping as you type.
  money,

  /// A card number, grouped `#### #### #### ####`.
  creditCard,

  /// A card expiry, masked `MM/YY`.
  cardExpiry,

  /// A card security code: 3–4 digits.
  cvv;

  /// The keyboard to raise.
  TextInputType get keyboardType => switch (this) {
    AppInputFormat.multiline => TextInputType.multiline,
    AppInputFormat.personName => TextInputType.name,
    AppInputFormat.email => TextInputType.emailAddress,
    AppInputFormat.url => TextInputType.url,
    AppInputFormat.phone => TextInputType.phone,
    AppInputFormat.integer ||
    AppInputFormat.creditCard ||
    AppInputFormat.cardExpiry ||
    AppInputFormat.cvv => TextInputType.number,
    AppInputFormat.decimal || AppInputFormat.money =>
      const TextInputType.numberWithOptions(decimal: true),
    AppInputFormat.text ||
    AppInputFormat.password ||
    AppInputFormat.username => TextInputType.text,
  };

  /// Formatters applied on every keystroke, so the field can only ever hold
  /// something shaped like its format. Passing `inputFormatters` to an input
  /// replaces this list.
  List<TextInputFormatter> get formatters => switch (this) {
    AppInputFormat.email => [_noSpaces, const LowerCaseInputFormatter()],
    AppInputFormat.url => [_noSpaces],
    AppInputFormat.username => [_usernameChars],
    AppInputFormat.phone => [_phoneChars],
    AppInputFormat.integer ||
    AppInputFormat.cvv => [FilteringTextInputFormatter.digitsOnly],
    AppInputFormat.decimal => [const DecimalInputFormatter()],
    AppInputFormat.money => [const MoneyInputFormatter()],
    AppInputFormat.creditCard => [
      const MaskedInputFormatter('#### #### #### ####'),
    ],
    AppInputFormat.cardExpiry => [const MaskedInputFormatter('##/##')],
    _ => const [],
  };

  /// The rule [ValidationService] checks the value against.
  InputType get validationType => switch (this) {
    AppInputFormat.email => InputType.email,
    AppInputFormat.password => InputType.password,
    AppInputFormat.username => InputType.username,
    AppInputFormat.url => InputType.url,
    AppInputFormat.phone => InputType.phone,
    AppInputFormat.creditCard => InputType.creditCard,
    AppInputFormat.cardExpiry => InputType.cardExpiry,
    AppInputFormat.cvv => InputType.cvv,
    AppInputFormat.integer ||
    AppInputFormat.decimal ||
    AppInputFormat.money => InputType.number,
    AppInputFormat.text ||
    AppInputFormat.multiline ||
    AppInputFormat.personName => InputType.text,
  };

  /// Whether the value is hidden until the user asks to see it.
  bool get isObscured => this == AppInputFormat.password;

  /// Whether the field should grow past one line.
  bool get isMultiline => this == AppInputFormat.multiline;

  /// The cap the format carries on its own — the mask's own width for cards
  /// and expiries. `null` means uncapped.
  int? get maxLength => switch (this) {
    AppInputFormat.creditCard => 19,
    AppInputFormat.cardExpiry => 5,
    AppInputFormat.cvv => 4,
    _ => null,
  };

  /// How the keyboard capitalises what is typed.
  TextCapitalization get textCapitalization => switch (this) {
    AppInputFormat.personName => TextCapitalization.words,
    AppInputFormat.multiline => TextCapitalization.sentences,
    _ => TextCapitalization.none,
  };

  /// Hints that let the OS offer a saved value — keychain, address book, or
  /// the card scanner.
  List<String>? get autofillHints => switch (this) {
    AppInputFormat.personName => const [AutofillHints.name],
    AppInputFormat.email => const [AutofillHints.email],
    AppInputFormat.password => const [AutofillHints.password],
    AppInputFormat.username => const [AutofillHints.username],
    AppInputFormat.url => const [AutofillHints.url],
    AppInputFormat.phone => const [AutofillHints.telephoneNumber],
    AppInputFormat.creditCard => const [AutofillHints.creditCardNumber],
    AppInputFormat.cardExpiry => const [AutofillHints.creditCardExpirationDate],
    AppInputFormat.cvv => const [AutofillHints.creditCardSecurityCode],
    _ => null,
  };

  /// The value with the punctuation this format added stripped back out — what
  /// you send to an API or hand to `num.parse`.
  ///
  ///   AppInputFormat.money.unformat('1,234.50')            // 1234.50
  ///   AppInputFormat.creditCard.unformat('4111 1111 ...')  // 41111111...
  ///
  /// Formats that add nothing return the value untouched.
  String unformat(String value) => switch (this) {
    AppInputFormat.money =>
      value
          .replaceAll(moneyGroupSeparator, '')
          .replaceAll(moneyDecimalSeparator, '.'),
    AppInputFormat.creditCard ||
    AppInputFormat.cardExpiry ||
    AppInputFormat.cvv => _digitsOnly(value),
    AppInputFormat.phone => value.replaceAll(RegExp(r'[^\d+]'), ''),
    _ => value,
  };

  /// The format a bare [TextInputType] implies — the bridge for fields written
  /// as `keyboardType:` before formats existed. `null` when nothing matches.
  static AppInputFormat? forKeyboardType(TextInputType? keyboardType) {
    if (keyboardType == null) return null;
    if (keyboardType == TextInputType.emailAddress) return AppInputFormat.email;
    if (keyboardType == TextInputType.phone) return AppInputFormat.phone;
    if (keyboardType == TextInputType.url) return AppInputFormat.url;
    if (keyboardType == TextInputType.name) return AppInputFormat.personName;
    if (keyboardType == TextInputType.multiline) {
      return AppInputFormat.multiline;
    }
    if (keyboardType == TextInputType.number) return AppInputFormat.integer;
    if (keyboardType == const TextInputType.numberWithOptions(decimal: true)) {
      return AppInputFormat.decimal;
    }
    return null;
  }
}

/// Keeps a decimal number well-formed as it is typed: digits, one separator,
/// and at most [decimalDigits] after it. An edit that would break the shape is
/// rejected rather than corrected, so the caret never jumps.
///
/// Whichever separator key the keyboard offers produces [separator], so the
/// field behaves the same on a comma keyboard as on a dot one.
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({
    this.decimalDigits = 2,
    this.allowNegative = false,
    this.separator = moneyDecimalSeparator,
  });

  final int decimalDigits;
  final bool allowNegative;
  final String separator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // A 1:1 replacement, so the selection offsets stay valid.
    final text = newValue.text.replaceAll(RegExp(r'[.,]'), separator);
    final sign = allowNegative ? '-?' : '';
    final tail = decimalDigits > 0
        ? '(${RegExp.escape(separator)}\\d{0,$decimalDigits})?'
        : '';

    if (!RegExp('^$sign\\d*$tail\$').hasMatch(text)) return oldValue;
    return newValue.copyWith(text: text);
  }
}

/// Groups the whole part of an amount as it is typed — `1234.5` shows as
/// `1,234.5` — and puts the caret back where the user left it.
///
/// [decimalSeparator] is the only key that opens the decimal part; the
/// grouping punctuation is this formatter's own and is ignored on the way in.
/// Flip the two for a locale that writes `1.234,50`.
///
/// Read the plain number back with `AppInputFormat.money.unformat(text)`.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({
    this.decimalDigits = 2,
    this.allowNegative = false,
    this.maxIntegerDigits = 12,
    this.groupSeparator = moneyGroupSeparator,
    this.decimalSeparator = moneyDecimalSeparator,
  });

  final int decimalDigits;
  final bool allowNegative;
  final int maxIntegerDigits;
  final String groupSeparator;
  final String decimalSeparator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Anchor the caret to the digits that follow it: the separators move
    // around as the value grows, the digits after the caret don't.
    final trailingDigits = _digitsAfterCaret(newValue);

    final negative = allowNegative && newValue.text.startsWith('-');
    // Only [decimalSeparator] opens the decimal part — the other punctuation
    // is this formatter's own grouping, so it cannot mean both things.
    final stripped = newValue.text.replaceAll(groupSeparator, '');
    final split = decimalDigits > 0 ? stripped.indexOf(decimalSeparator) : -1;

    var whole = _digitsOnly(
      split == -1 ? stripped : stripped.substring(0, split),
    );
    var fraction = split == -1
        ? ''
        : _digitsOnly(stripped.substring(split + 1));

    if (whole.length > 1) {
      whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    }
    if (whole.length > maxIntegerDigits) {
      whole = whole.substring(0, maxIntegerDigits);
    }
    if (fraction.length > decimalDigits) {
      fraction = fraction.substring(0, decimalDigits);
    }

    final buffer = StringBuffer(negative ? '-' : '')
      ..write(_group(whole, groupSeparator));
    if (split != -1) {
      buffer
        ..write(decimalSeparator)
        ..write(fraction);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetLeaving(text, trailingDigits),
      ),
    );
  }
}

/// Types the punctuation for the user: `#` is a digit slot, every other
/// character is a literal the field fills in as the slots around it fill.
///
///   MaskedInputFormatter('#### #### #### ####')  // 4111 1111 1111 1111
///   MaskedInputFormatter('##/##')                // 12/25
///   MaskedInputFormatter('(###) ###-####')       // (555) 010-9999
///
/// Digits past the last slot are dropped, so the mask is also the length cap.
class MaskedInputFormatter extends TextInputFormatter {
  const MaskedInputFormatter(this.mask, {this.slot = '#'});

  final String mask;
  final String slot;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trailingDigits = _digitsAfterCaret(newValue);
    final slots = slot.allMatches(mask).length;

    var digits = _digitsOnly(newValue.text);
    if (digits.length > slots) digits = digits.substring(0, slots);

    // Literals are only written while a digit still needs a slot, so a
    // half-typed value never ends on a dangling separator.
    final buffer = StringBuffer();
    var next = 0;
    for (var i = 0; i < mask.length && next < digits.length; i++) {
      buffer.write(mask[i] == slot ? digits[next++] : mask[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetLeaving(text, trailingDigits),
      ),
    );
  }
}

/// Lower-cases as the user types — emails and handles are case-insensitive, so
/// a capital from the keyboard's auto-shift shouldn't reach your API.
class LowerCaseInputFormatter extends TextInputFormatter {
  const LowerCaseInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toLowerCase();
    // A few scripts change length when cased, which would invalidate the
    // selection; leave those alone.
    return text.length == newValue.text.length
        ? newValue.copyWith(text: text)
        : newValue;
  }
}

/// Upper-cases as the user types — coupon codes, plates, reference numbers.
class UpperCaseInputFormatter extends TextInputFormatter {
  const UpperCaseInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    return text.length == newValue.text.length
        ? newValue.copyWith(text: text)
        : newValue;
  }
}

final _noSpaces = FilteringTextInputFormatter.deny(RegExp(r'\s'));
final _usernameChars = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-Z0-9_-]'),
);
final _phoneChars = FilteringTextInputFormatter.allow(RegExp(r'[\d()+\- ]'));
final _nonDigits = RegExp(r'\D');
final _digit = RegExp(r'\d');

String _digitsOnly(String value) => value.replaceAll(_nonDigits, '');

/// Groups [digits] in threes from the right: `1234567` -> `1,234,567`.
String _group(String digits, String separator) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// How many digits sit after the caret — the part of the value an edit leaves
/// untouched, and so the anchor a re-formatted string can be measured against.
int _digitsAfterCaret(TextEditingValue value) {
  final caret = value.selection.end;
  if (caret < 0 || caret > value.text.length) return 0;
  return _digitsOnly(value.text.substring(caret)).length;
}

/// The offset in [text] that leaves exactly [digits] digits after it.
int _offsetLeaving(String text, int digits) {
  if (digits <= 0) return text.length;
  var seen = 0;
  for (var i = text.length - 1; i >= 0; i--) {
    if (_digit.hasMatch(text[i])) {
      seen++;
      if (seen == digits) return i;
    }
  }
  return 0;
}
