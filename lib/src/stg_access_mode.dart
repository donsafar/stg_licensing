/// How the app may interact with local data for the current licensing state.
enum StgAccessMode {
  /// Normal operation — database writes allowed (tier gates still apply).
  full,

  /// Trial or subscription ended — view data only; no database writes or exports.
  readOnly,

  /// Optional hard block (fraud / policy); not used for normal trial/subscription lapse.
  blocked,
}
