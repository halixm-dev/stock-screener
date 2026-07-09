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
  final int completed;
  final int total;

  const ScreenerScanning({this.completed = 0, this.total = 0});

  @override
  List<Object?> get props => [completed, total];
}

class ScreenerError extends ScreenerState {
  final String message;

  const ScreenerError(this.message);

  @override
  List<Object?> get props => [message];
}
