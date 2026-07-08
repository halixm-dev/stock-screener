import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/screener_service.dart';

part 'screener_state.dart';

class ScreenerCubit extends Cubit<ScreenerState> {
  final ScreenerService screenerService;

  ScreenerCubit({required this.screenerService})
    : super(const ScreenerInitial());

  Future<void> runScan({required List<String> symbols}) async {
    emit(const ScreenerScanning());
    try {
      await screenerService.runScan(symbols: symbols);
      emit(const ScreenerInitial());
    } catch (e) {
      emit(ScreenerError(e.toString()));
    }
  }
}
