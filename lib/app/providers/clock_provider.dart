import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current instant, as a function so a test can decide what "now" is.
///
/// Only the calendar bounds of the date picker consult it: a driver cannot
/// publish a journey into the past, so the picker should not offer one. That is
/// a courtesy, not the rule — whether a departure has actually passed is read
/// in the pilot's timezone, on the server, and this client neither knows nor
/// guesses it.
///
/// A function rather than a value, because a widget built once must not keep
/// answering with the instant it was built at.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);
