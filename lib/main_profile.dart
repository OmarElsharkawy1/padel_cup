import 'bootstrap.dart';
import 'core/config/app_config.dart';

void main() {
  bootstrap(const AppConfig(
    environment: Environment.profile,
    appName: 'Padel Cup [PROFILE]',
  ));
}
