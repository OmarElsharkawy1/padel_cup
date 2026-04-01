enum Environment { dev, staging, profile, release }

class AppConfig {
  final Environment environment;
  final String appName;

  const AppConfig({
    required this.environment,
    required this.appName,
  });

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProfile => environment == Environment.profile;
  bool get isRelease => environment == Environment.release;
}
