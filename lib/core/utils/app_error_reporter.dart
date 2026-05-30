import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppErrorReporter {
  const AppErrorReporter._();

  static void record(Object error, StackTrace stackTrace, {String? reason}) {
    if (kDebugMode) {
      debugPrint('${reason ?? 'Non-fatal error'}: $error');
    }
    if (!kIsWeb) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason,
        ),
      );
    }
  }
}
