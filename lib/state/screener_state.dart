part of 'screener_cubit.dart';

sealed class ScreenerState extends Equatable {
  const ScreenerState();
  @override
  List<Object?> get props => [];
}

class ScreenerInitial extends ScreenerState {
  const ScreenerInitial();
}

class ScreenerScanning extends ScreenerState {
  const ScreenerScanning();
}

class ScreenerComplete extends ScreenerState {
  final List<ScreenResult> results;
  final int totalProcessed;
  final int totalSkipped;

  const ScreenerComplete({
    required this.results,
    required this.totalProcessed,
    required this.totalSkipped,
  });

  @override
  List<Object?> get props => [results, totalProcessed, totalSkipped];
}

class ScreenerError extends ScreenerState {
  final String message;

  const ScreenerError(this.message);

  @override
  List<Object?> get props => [message];
}
