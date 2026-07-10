import 'package:equatable/equatable.dart';

class ScreenSignalConfig extends Equatable {
  final String leadingIndicator;
  final List<String> confirmations;
  final Map<String, Map<String, dynamic>> parameters;
  final List<String> universe;
  final int scanIntervalMinutes;
  final String universePreset;

  const ScreenSignalConfig({
    this.leadingIndicator = 'Range Filter',
    this.confirmations = const [],
    this.parameters = const {},
    this.universe = const [],
    this.scanIntervalMinutes = 60,
    this.universePreset = 'lq45',
  });

  factory ScreenSignalConfig.fromJson(Map<String, dynamic> json) {
    return ScreenSignalConfig(
      leadingIndicator: json['leadingIndicator'] as String? ?? 'Range Filter',
      confirmations:
          (json['confirmations'] as List<dynamic>?)?.cast<String>() ?? const [],
      parameters:
          (json['parameters'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, Map<String, dynamic>.from(e as Map)),
          ) ??
          const {},
      universe:
          (json['universe'] as List<dynamic>?)?.cast<String>() ??
          const [],
      scanIntervalMinutes: json['scanIntervalMinutes'] as int? ?? 60,
      universePreset: json['universePreset'] as String? ?? 'lq45',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leadingIndicator': leadingIndicator,
      'confirmations': confirmations,
      'parameters': parameters,
      'universe': universe,
      'scanIntervalMinutes': scanIntervalMinutes,
      'universePreset': universePreset,
    };
  }

  ScreenSignalConfig copyWith({
    String? leadingIndicator,
    List<String>? confirmations,
    Map<String, Map<String, dynamic>>? parameters,
    List<String>? universe,
    int? scanIntervalMinutes,
    String? universePreset,
  }) {
    return ScreenSignalConfig(
      leadingIndicator: leadingIndicator ?? this.leadingIndicator,
      confirmations: confirmations ?? this.confirmations,
      parameters: parameters ?? this.parameters,
      universe: universe ?? this.universe,
      scanIntervalMinutes: scanIntervalMinutes ?? this.scanIntervalMinutes,
      universePreset: universePreset ?? this.universePreset,
    );
  }

  @override
  List<Object?> get props => [
    leadingIndicator,
    confirmations,
    parameters,
    universe,
    scanIntervalMinutes,
    universePreset,
  ];
}
