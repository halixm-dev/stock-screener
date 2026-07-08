// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_signal_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScreenSignalConfig _$ScreenSignalConfigFromJson(Map<String, dynamic> json) =>
    _ScreenSignalConfig(
      leadingIndicator: json['leadingIndicator'] as String? ?? 'Range Filter',
      confirmations:
          (json['confirmations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      parameters:
          (json['parameters'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as Map<String, dynamic>),
          ) ??
          const {},
    );

Map<String, dynamic> _$ScreenSignalConfigToJson(_ScreenSignalConfig instance) =>
    <String, dynamic>{
      'leadingIndicator': instance.leadingIndicator,
      'confirmations': instance.confirmations,
      'parameters': instance.parameters,
    };
