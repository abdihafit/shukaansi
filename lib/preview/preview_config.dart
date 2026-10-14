import 'package:flutter/foundation.dart';

/// Set with `--dart-define=SHUKAANSI_PREVIEW=true`; off unless asked for.
const previewRequested = bool.fromEnvironment('SHUKAANSI_PREVIEW');

/// The development preview runs only when explicitly requested AND the build
/// is not a release build. Release builds can never show fictional profiles.
bool previewAllowed({
  bool release = kReleaseMode,
  bool requested = previewRequested,
}) => requested && !release;
