import 'package:equatable/equatable.dart';

class ScreenSignalConfig extends Equatable {
  final String leadingIndicator;
  final List<String> confirmations;
  final Map<String, Map<String, dynamic>> parameters;
  final List<String> universe;

  const ScreenSignalConfig({
    this.leadingIndicator = 'Range Filter',
    this.confirmations = const [],
    this.parameters = const {},
    this.universe = const [],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leadingIndicator': leadingIndicator,
      'confirmations': confirmations,
      'parameters': parameters,
      'universe': universe,
    };
  }

  ScreenSignalConfig copyWith({
    String? leadingIndicator,
    List<String>? confirmations,
    Map<String, Map<String, dynamic>>? parameters,
    List<String>? universe,
  }) {
    return ScreenSignalConfig(
      leadingIndicator: leadingIndicator ?? this.leadingIndicator,
      confirmations: confirmations ?? this.confirmations,
      parameters: parameters ?? this.parameters,
      universe: universe ?? this.universe,
    );
  }

  @override
  List<Object?> get props => [
    leadingIndicator,
    confirmations,
    parameters,
    universe,
  ];
}
