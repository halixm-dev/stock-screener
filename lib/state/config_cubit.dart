import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/config_repository.dart';
import '../data/models/screen_signal_config.dart';
import 'config_state.dart';

class ConfigCubit extends Cubit<ConfigState> {
  final ConfigRepository _repository;

  ConfigCubit(this._repository)
    : super(const ConfigState(ScreenSignalConfig(), false));

  Future<void> loadConfig() async {
    final config = await _repository.getConfig();
    final isBackgroundEnabled = _repository.isBackgroundScanEnabled();
    final interval = _repository.getScanIntervalMinutes();
    emit(ConfigState(
      config.copyWith(scanIntervalMinutes: interval),
      isBackgroundEnabled,
    ));
  }

  Future<void> updateConfig(ScreenSignalConfig newConfig) async {
    await _repository.saveConfig(newConfig);
    emit(ConfigState(newConfig, state.isBackgroundScanEnabled));
  }

  Future<void> setBackgroundScanEnabled(bool enabled) async {
    await _repository.setBackgroundScanEnabled(enabled);
    emit(ConfigState(state.config, enabled));
  }

  Future<void> setScanInterval(int minutes) async {
    await _repository.setScanIntervalMinutes(minutes);
    final updated = state.config.copyWith(scanIntervalMinutes: minutes);
    await _repository.saveConfig(updated);
    emit(ConfigState(updated, state.isBackgroundScanEnabled));
  }
}
