import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/ride_mate_app.dart';

void main() {
  // ProviderScope is the outermost widget and main() stays synchronous:
  // no I/O before the first frame, which keeps startup fast and testable.
  runApp(const ProviderScope(child: RideMateApp()));
}
