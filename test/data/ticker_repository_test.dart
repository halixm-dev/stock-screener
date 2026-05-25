import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stock_screener/data/ticker_repository.dart';
import 'package:stock_screener/domain/ohlcv_data.dart';

class MockTickerRepository extends Mock implements TickerRepository {}

void main() {
  late MockTickerRepository mockRepo;
  late TickerInfo ticker;
  late List<TickerInfo> universe;
  late OhlcvData ohlcv;

  setUpAll(() {
    registerFallbackValue(
      OhlcvData(open: [], high: [], low: [], close: [], volume: []),
    );
    registerFallbackValue(TickerInfo(symbol: '', name: ''));
    registerFallbackValue(<TickerInfo>[]);
  });

  setUp(() {
    mockRepo = MockTickerRepository();
    ticker = TickerInfo(symbol: 'AAPL', name: 'Apple Inc.');
    universe = [
      ticker,
      TickerInfo(symbol: 'GOOG', name: 'Alphabet Inc.'),
      TickerInfo(symbol: 'MSFT', name: 'Microsoft Corporation'),
    ];
    ohlcv = OhlcvData(
      open: [150.0, 151.0],
      high: [155.0, 153.0],
      low: [149.0, 150.0],
      close: [154.0, 152.0],
      volume: [100000, 120000],
    );
  });

  group('TickerRepository (abstract interface)', () {
    test('MockTickerRepository can be instantiated', () {
      expect(mockRepo, isA<TickerRepository>());
    });

    group('fetchUniverse', () {
      test('returns list of TickerInfo', () async {
        when(() => mockRepo.fetchUniverse()).thenAnswer((_) async => universe);

        final result = await mockRepo.fetchUniverse();

        expect(result, same(universe));
        expect(result, hasLength(3));
        expect(result.first.symbol, 'AAPL');
        expect(result.first.name, 'Apple Inc.');
        verify(() => mockRepo.fetchUniverse()).called(1);
      });

      test('can return empty list', () async {
        when(() => mockRepo.fetchUniverse()).thenAnswer((_) async => []);

        final result = await mockRepo.fetchUniverse();

        expect(result, isEmpty);
      });
    });

    group('fetchOhlcv', () {
      test('returns OhlcvData for a symbol', () async {
        when(() => mockRepo.fetchOhlcv('AAPL')).thenAnswer((_) async => ohlcv);

        final result = await mockRepo.fetchOhlcv('AAPL');

        expect(result, same(ohlcv));
        expect(result!.close.last, 152.0);
        verify(() => mockRepo.fetchOhlcv('AAPL')).called(1);
      });

      test('can return null for unknown symbol', () async {
        when(() => mockRepo.fetchOhlcv('UNKNOWN')).thenAnswer((_) async => null);

        final result = await mockRepo.fetchOhlcv('UNKNOWN');

        expect(result, isNull);
      });

      test('passes symbol argument correctly', () async {
        when(() => mockRepo.fetchOhlcv(any())).thenAnswer((_) async => ohlcv);

        await mockRepo.fetchOhlcv('TSLA');

        verify(() => mockRepo.fetchOhlcv('TSLA')).called(1);
      });
    });

    group('cacheOhlcv', () {
      test('caches OhlcvData without error', () async {
        when(() => mockRepo.cacheOhlcv(any(), any()))
            .thenAnswer((_) async {});

        await expectLater(
          mockRepo.cacheOhlcv('AAPL', ohlcv),
          completes,
        );

        verify(() => mockRepo.cacheOhlcv('AAPL', ohlcv)).called(1);
      });

      test('captures arguments correctly', () async {
        when(() => mockRepo.cacheOhlcv(any(), any()))
            .thenAnswer((_) async {});

        await mockRepo.cacheOhlcv('MSFT', ohlcv);

        final captured = verify(() => mockRepo.cacheOhlcv(captureAny(), captureAny()))
            .captured;
        expect(captured[0], 'MSFT');
        expect(captured[1], same(ohlcv));
      });
    });

    group('getCachedOhlcv', () {
      test('returns cached OhlcvData', () async {
        when(() => mockRepo.getCachedOhlcv('AAPL'))
            .thenAnswer((_) async => ohlcv);

        final result = await mockRepo.getCachedOhlcv('AAPL');

        expect(result, same(ohlcv));
        expect(result!.open.first, 150.0);
        verify(() => mockRepo.getCachedOhlcv('AAPL')).called(1);
      });

      test('returns null when no cache', () async {
        when(() => mockRepo.getCachedOhlcv('AAPL'))
            .thenAnswer((_) async => null);

        final result = await mockRepo.getCachedOhlcv('AAPL');

        expect(result, isNull);
      });
    });

    group('cacheUniverse', () {
      test('caches universe without error', () async {
        when(() => mockRepo.cacheUniverse(any())).thenAnswer((_) async {});

        await expectLater(
          mockRepo.cacheUniverse(universe),
          completes,
        );

        verify(() => mockRepo.cacheUniverse(universe)).called(1);
      });

      test('captures ticker list argument', () async {
        when(() => mockRepo.cacheUniverse(any())).thenAnswer((_) async {});

        await mockRepo.cacheUniverse(universe);

        final captured =
            verify(() => mockRepo.cacheUniverse(captureAny())).captured;
        expect(captured.first, isA<List<TickerInfo>>());
        expect((captured.first as List<TickerInfo>), hasLength(3));
      });
    });

    group('getCachedUniverse', () {
      test('returns cached universe', () async {
        when(() => mockRepo.getCachedUniverse())
            .thenAnswer((_) async => universe);

        final result = await mockRepo.getCachedUniverse();

        expect(result, same(universe));
        expect(result, hasLength(3));
        verify(() => mockRepo.getCachedUniverse()).called(1);
      });

      test('returns null when no cached universe', () async {
        when(() => mockRepo.getCachedUniverse())
            .thenAnswer((_) async => null);

        final result = await mockRepo.getCachedUniverse();

        expect(result, isNull);
      });
    });

    group('getLastCachedDate', () {
      test('returns DateTime when cache exists', () async {
        final date = DateTime(2026, 5, 25);
        when(() => mockRepo.getLastCachedDate())
            .thenAnswer((_) async => date);

        final result = await mockRepo.getLastCachedDate();

        expect(result, same(date));
        expect(result!.year, 2026);
        expect(result.month, 5);
        expect(result.day, 25);
        verify(() => mockRepo.getLastCachedDate()).called(1);
      });

      test('returns null when never cached', () async {
        when(() => mockRepo.getLastCachedDate())
            .thenAnswer((_) async => null);

        final result = await mockRepo.getLastCachedDate();

        expect(result, isNull);
      });
    });
  });

  group('YahooFinanceTickerRepository', () {
    late YahooFinanceTickerRepository repo;

    setUp(() {
      repo = YahooFinanceTickerRepository();
    });

    test('can be instantiated with defaults', () {
      expect(repo.apiBase, 'https://query1.finance.yahoo.com/v8/finance/chart');
      expect(repo.batchSize, 20);
      expect(repo.throttleMs, 500);
    });

    test('can be instantiated with custom values', () {
      final custom = YahooFinanceTickerRepository(
        apiBase: 'https://custom.api',
        batchSize: 10,
        throttleMs: 1000,
      );
      expect(custom.apiBase, 'https://custom.api');
      expect(custom.batchSize, 10);
      expect(custom.throttleMs, 1000);
    });

    group('throws UnimplementedError for all methods', () {
      test('fetchUniverse', () async {
        expect(
          () => repo.fetchUniverse(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('fetchOhlcv', () async {
        expect(
          () => repo.fetchOhlcv('AAPL'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('cacheOhlcv', () async {
        final d = OhlcvData(
          open: [150.0],
          high: [155.0],
          low: [149.0],
          close: [154.0],
          volume: [100000],
        );
        expect(
          () => repo.cacheOhlcv('AAPL', d),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getCachedOhlcv', () async {
        expect(
          () => repo.getCachedOhlcv('AAPL'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('cacheUniverse', () async {
        final ts = [TickerInfo(symbol: 'AAPL', name: 'Apple Inc.')];
        expect(
          () => repo.cacheUniverse(ts),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getCachedUniverse', () async {
        expect(
          () => repo.getCachedUniverse(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('getLastCachedDate', () async {
        expect(
          () => repo.getLastCachedDate(),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });
}
