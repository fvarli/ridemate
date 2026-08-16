// ─────────────────────────────────────────────────────────────
// RideMate — Text conventions
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// Locale-independent presentation rules the design applies consistently.
// These are pure functions so they can be unit-tested exhaustively; several
// of them touch privacy-sensitive data and must not drift.
// ─────────────────────────────────────────────────────────────

/// Presentation rules for names, phone numbers and vehicle plates.
abstract final class RmTextConventions {
  const RmTextConventions._();

  /// Joins metadata fragments with the design's middle-dot separator.
  ///
  /// Empty and blank fragments are dropped so a missing value never leaves a
  /// dangling separator.
  static String joinMeta(Iterable<String?> parts) => parts
      .where((String? p) => p != null && p.trim().isNotEmpty)
      .map((String? p) => p!.trim())
      .join(' · ');

  /// Formats a route as `Kadıköy → Levent`.
  static String route(String origin, String destination) =>
      '$origin → $destination';

  /// Abbreviates another member's name to first name plus surname initial,
  /// e.g. `Selin Kaya` -> `Selin K.`.
  ///
  /// The design shows other people this way and only ever shows a full name
  /// on one's own profile. This is a privacy default, so it fails closed:
  /// anything it cannot parse is returned unchanged rather than guessed at.
  static String abbreviateName(String fullName) {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();

    if (parts.length < 2) return fullName.trim();

    return '${parts.first} ${upperTr(parts.last.substring(0, 1))}.';
  }

  /// Initials for an avatar, e.g. `Selin Kaya` -> `SK`.
  static String initials(String fullName) {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) return upperTr(parts.first.substring(0, 1));
    return upperTr(parts.first.substring(0, 1) + parts.last.substring(0, 1));
  }

  /// Turkish-aware uppercase.
  ///
  /// Dart's [String.toUpperCase] is locale-independent and maps `i` to `I`,
  /// which is wrong in Turkish: dotted `i` uppercases to `İ`, and dotless `ı`
  /// uppercases to `I`. Getting this wrong renders a member's initials
  /// incorrectly — `İrem` would show as `Irem` — which is exactly the kind of
  /// detail that undermines trust in a Turkish-first product.
  static String upperTr(String input) =>
      input.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// Turkish-aware lowercase, the inverse of [upperTr].
  static String lowerTr(String input) =>
      input.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// Masks a phone number for display, e.g. `+90 5551234542`
  /// -> `+90 5•• ••• 42`.
  ///
  /// Matches the design's verification screen. Fails closed: an input it
  /// cannot confidently mask is fully masked rather than partly revealed.
  static String maskPhone(String phone) {
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6) return '•' * (digits.isEmpty ? 3 : digits.length);

    // Turkish mobile numbers: +90 followed by 10 digits.
    final bool hasCountryCode = digits.length > 10 && digits.startsWith('90');
    final String national = hasCountryCode ? digits.substring(2) : digits;
    if (national.length < 4) return '•' * national.length;

    final String lead = national.substring(0, 1);
    final String tail = national.substring(national.length - 2);
    final String masked = '$lead•• ••• $tail';
    return hasCountryCode ? '+90 $masked' : masked;
  }

  /// Normalises a Turkish vehicle plate for display, e.g. `34abc128`
  /// -> `34 ABC 128`.
  ///
  /// Returns the trimmed, uppercased input unchanged when it does not match
  /// the Turkish plate shape, so foreign or unusual plates are never mangled.
  static String plate(String raw) {
    final String cleaned = upperTr(raw.replaceAll(RegExp(r'\s+'), ''));
    final RegExpMatch? m = RegExp(
      r'^(\d{2})([A-ZÇĞİÖŞÜ]{1,3})(\d{2,5})$',
    ).firstMatch(cleaned);

    if (m == null) return upperTr(raw.trim());
    return '${m.group(1)} ${m.group(2)} ${m.group(3)}';
  }
}
