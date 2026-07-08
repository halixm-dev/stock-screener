import 'package:equatable/equatable.dart';

class ScreenSignalConfig extends Equatable {
  final String leadingIndicator;
  final List<String> confirmations;
  final Map<String, Map<String, dynamic>> parameters;

  const ScreenSignalConfig({
    this.leadingIndicator = 'Range Filter',
    this.confirmations = const [],
    this.parameters = const {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leadingIndicator': leadingIndicator,
      'confirmations': confirmations,
      'parameters': parameters,
    };
  }

  ScreenSignalConfig copyWith({
    String? leadingIndicator,
    List<String>? confirmations,
    Map<String, Map<String, dynamic>>? parameters,
  }) {
    return ScreenSignalConfig(
      leadingIndicator: leadingIndicator ?? this.leadingIndicator,
      confirmations: confirmations ?? this.confirmations,
      parameters: parameters ?? this.parameters,
    );
  }

  @override
  List<Object?> get props => [leadingIndicator, confirmations, parameters];
}
