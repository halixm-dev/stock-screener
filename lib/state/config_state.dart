import 'package:equatable/equatable.dart';
import '../data/models/screen_signal_config.dart';

class ConfigState extends Equatable {
  final ScreenSignalConfig config;
  final bool isBackgroundScanEnabled;

  const ConfigState(this.config, this.isBackgroundScanEnabled);

  @override
  List<Object> get props => [config, isBackgroundScanEnabled];
}
