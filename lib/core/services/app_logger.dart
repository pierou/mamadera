import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Factory creating the application-wide [Logger].
///
/// Every class that logs must obtain its logger here instead of calling
/// `Logger()` directly: in release builds the level is raised to
/// [Level.warning], so `debug`/`info` traces (which carry row identifiers and
/// internal messages) never reach Android logcat or the iOS device console.
/// Unhandled errors and warnings remain visible in production.
///
/// Debug builds keep the `logger` package default level ([Level.all]).
Logger appLogger() {
  return Logger(level: kReleaseMode ? Level.warning : Level.all);
}
