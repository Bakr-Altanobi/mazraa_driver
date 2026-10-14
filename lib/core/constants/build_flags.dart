abstract final class BuildFlags {
  static const ciSmokeHome = bool.fromEnvironment(
    'CI_SMOKE_HOME',
    defaultValue: false,
  );
}
