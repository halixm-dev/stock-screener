import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/screener_service.dart';

part 'screener_state.dart';

class ScreenerCubit extends Cubit<ScreenerState> {
  final ScreenerService screenerService;

  ScreenerCubit({required this.screenerService})
    : super(const ScreenerInitial());

  Future<void> runScan({required List<String> symbols}) async {
    emit(ScreenerScanning(completed: 0, total: symbols.length));
    try {
      await screenerService.runScan(
        symbols: symbols,
        onProgress: (completed, total) {
          emit(ScreenerScanning(completed: completed, total: total));
        },
      );
      emit(const ScreenerInitial());
    } catch (e) {
      emit(ScreenerError(e.toString()));
    }
  }
}
