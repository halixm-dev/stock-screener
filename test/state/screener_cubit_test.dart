import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stock_screener/state/screener_cubit.dart';
import 'package:stock_screener/data/ticker_repository.dart';
import 'package:stock_screener/domain/ohlcv_data.dart';
import 'package:stock_screener/domain/ticker_filter.dart';
import 'package:stock_screener/domain/signal_engine.dart';

class MockTickerRepository extends Mock implements TickerRepository {}

class MockTickerFilter extends Mock implements TickerFilter {}

class MockSignalEngine extends Mock implements SignalEngine {}

OhlcvData _createOhlcvData() {
  return OhlcvData(
    open: List.generate(150, (i) => 100.0 + i * 0.5),
    high: List.generate(150, (i) => 105.0 + i * 0.5),
    low: List.generate(150, (i) => 95.0 + i * 0.5),
    close: List.generate(150, (i) => 100.0 + i * 0.5),
    volume: List.generate(150, (_) => 1000000),
  );
}

void main() {
  late MockTickerRepository repository;
  late MockTickerFilter filter;
  late MockSignalEngine signalEngine;
  late OhlcvData testData;

  setUpAll(() {
    registerFallbackValue(OhlcvData(
      open: [],
      high: [],
      low: [],
      close: [],
      volume: [],
    ));
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    repository = MockTickerRepository();
    filter = MockTickerFilter();
    signalEngine = MockSignalEngine();
    testData = _createOhlcvData();
  });

  group('ScreenerCubit', () {
    blocTest<ScreenerCubit, ScreenerState>(
      'starts in ScreenerInitial state',
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      expect: () => [],
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan emits [ScreenerScanning, ScreenerComplete] with correct results when data is available and passes filter',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => null);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => testData);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(true);
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.buy);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        expect(state.results.length, 1);
        expect(state.results.first.symbol, 'AAPL');
        expect(state.results.first.signal, SignalType.buy);
        expect(state.results.first.price, testData.close.last);
        expect(state.totalProcessed, 1);
        expect(state.totalSkipped, 0);
        verify(() => repository.getCachedOhlcv('AAPL')).called(1);
        verify(() => repository.fetchOhlcv('AAPL')).called(1);
        verify(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).called(1);
        verify(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).called(1);
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan uses cached data when available (skips fetchOhlcv)',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => testData);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => null);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(true);
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.neutral);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['MSFT'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        verify(() => repository.getCachedOhlcv('MSFT')).called(1);
        verifyNever(() => repository.fetchOhlcv(any()));
        final state = cubit.state as ScreenerComplete;
        expect(state.results.length, 1);
        expect(state.totalProcessed, 1);
        expect(state.totalSkipped, 0);
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan increments totalSkipped when filter rejects data',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => null);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => testData);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(false);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        expect(state.results.length, 0);
        expect(state.totalProcessed, 0);
        expect(state.totalSkipped, 1);
        verifyNever(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        ));
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan increments totalSkipped when repository returns null',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => null);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => null);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        expect(state.results.length, 0);
        expect(state.totalProcessed, 0);
        expect(state.totalSkipped, 1);
        verifyNever(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        ));
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan handles multiple symbols, all kept',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => null);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => testData);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(true);
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.sell);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL', 'GOOGL', 'MSFT'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        expect(state.results.length, 3);
        expect(state.results[0].symbol, 'AAPL');
        expect(state.results[0].signal, SignalType.sell);
        expect(state.results[0].price, testData.close.last);
        expect(state.results[1].symbol, 'GOOGL');
        expect(state.results[2].symbol, 'MSFT');
        expect(state.totalProcessed, 3);
        expect(state.totalSkipped, 0);
        verify(() => repository.fetchOhlcv('AAPL')).called(1);
        verify(() => repository.fetchOhlcv('GOOGL')).called(1);
        verify(() => repository.fetchOhlcv('MSFT')).called(1);
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan with multiple symbols, mix of kept and skipped',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => null);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => testData);
        int keepCount = 0;
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenAnswer((_) {
          keepCount++;
          return keepCount != 2;
        });
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.buy);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['KEEP1', 'SKIP', 'KEEP2'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        expect(state.results.length, 2);
        expect(state.results[0].symbol, 'KEEP1');
        expect(state.results[1].symbol, 'KEEP2');
        expect(state.totalProcessed, 2);
        expect(state.totalSkipped, 1);
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan passes correct barIndex (data.length - 1) to signalEngine.evaluate',
      setUp: () {
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => null);
        when(() => repository.fetchOhlcv(any())).thenAnswer((_) async => testData);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(true);
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.buy);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        verify(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: testData.length - 1,
        )).called(1);
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan with 1-bar data sets changePercent to 0',
      setUp: () {
        final oneBarData = OhlcvData(
          open: [100.0],
          high: [105.0],
          low: [95.0],
          close: [100.0],
          volume: [1000000],
        );
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => oneBarData);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(true);
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.buy);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        expect(state.results.first.changePercent, 0);
      },
    );

    blocTest<ScreenerCubit, ScreenerState>(
      'runScan calculates changePercent correctly for 2+ bars',
      setUp: () {
        final twoBarData = OhlcvData(
          open: [100.0, 102.0],
          high: [105.0, 107.0],
          low: [95.0, 97.0],
          close: [100.0, 105.0],
          volume: [1000000, 1000000],
        );
        when(() => repository.getCachedOhlcv(any())).thenAnswer((_) async => twoBarData);
        when(() => filter.shouldKeep(
          data: any(named: 'data'),
          lastTradeDate: any(named: 'lastTradeDate'),
        )).thenReturn(true);
        when(() => signalEngine.evaluate(
          data: any(named: 'data'),
          barIndex: any(named: 'barIndex'),
        )).thenReturn(SignalType.buy);
      },
      build: () => ScreenerCubit(
        repository: repository,
        filter: filter,
        signalEngine: signalEngine,
      ),
      act: (cubit) => cubit.runScan(
        symbols: ['AAPL'],
        leadingIndicator: 'Range Filter',
      ),
      expect: () => [
        isA<ScreenerScanning>(),
        isA<ScreenerComplete>(),
      ],
      verify: (cubit) {
        final state = cubit.state as ScreenerComplete;
        final expected = ((105.0 - 100.0) / 100.0) * 100;
        expect(state.results.first.changePercent, expected);
        expect(state.results.first.price, 105.0);
      },
    );
  });
}
