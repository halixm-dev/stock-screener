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

class ScreenerError extends ScreenerState {
  final String message;

  const ScreenerError(this.message);

  @override
  List<Object?> get props => [message];
}
