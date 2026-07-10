import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:stock_screener/data/ticker_repository.dart';
import 'package:stock_screener/data/cache_entry.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockBox extends Mock implements Box {}

void main() {
  late YahooFinanceTickerRepository repository;
  late MockHttpClient mockHttpClient;
  late MockBox mockBox;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockBox = MockBox();
    repository = YahooFinanceTickerRepository(
      client: mockHttpClient,
      universeBox: mockBox,
    );

    registerFallbackValue(Uri());
  });

  group('fetchUniverse', () {
    final mockTickers = ['BBCA.JK', 'BMRI.JK'];
    final jsonResponse = jsonEncode(mockTickers);

    test('returns cached data if valid and not expired', () async {
      // Arrange
      final entry = CacheEntry<List<String>>(
        data: mockTickers,
        createdAt: DateTime.now(),
      );
      when(() => mockBox.get('tickers')).thenReturn(entry.toMap());

      // Act
      final result = await repository.fetchUniverse();

      // Assert
      expect(result, equals(mockTickers));
      verifyNever(() => mockHttpClient.get(any()));
    });

    test('fetches from network if cache is expired', () async {
      // Arrange
      final expiredEntry = CacheEntry<List<String>>(
        data: ['OLD.JK'],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      when(() => mockBox.get('tickers')).thenReturn(expiredEntry.toMap());
      when(() => mockBox.delete('tickers')).thenAnswer((_) async {});

      when(
        () => mockHttpClient.get(any()),
      ).thenAnswer((_) async => http.Response(jsonResponse, 200));
      when(() => mockBox.put('tickers', any())).thenAnswer((_) async {});

      // Act
      final result = await repository.fetchUniverse();

      // Assert
      expect(result, equals(mockTickers));
      verify(() => mockBox.delete('tickers')).called(1);
      verify(
        () => mockHttpClient.get(
          Uri.parse('https://halixm-dev.github.io/stock-screener/tickers.json'),
        ),
      ).called(1);
      verify(() => mockBox.put('tickers', any())).called(1);
    });

    test('fetches from network if no cache exists', () async {
      // Arrange
      when(() => mockBox.get('tickers')).thenReturn(null);
      when(
        () => mockHttpClient.get(any()),
      ).thenAnswer((_) async => http.Response(jsonResponse, 200));
      when(() => mockBox.put('tickers', any())).thenAnswer((_) async {});

      // Act
      final result = await repository.fetchUniverse();

      // Assert
      expect(result, equals(mockTickers));
      verify(
        () => mockHttpClient.get(
          Uri.parse('https://halixm-dev.github.io/stock-screener/tickers.json'),
        ),
      ).called(1);
      verify(() => mockBox.put('tickers', any())).called(1);
    });

    test('falls back to stale cache on network error', () async {
      // Arrange
      final expiredEntry = CacheEntry<List<String>>(
        data: ['STALE.JK'],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );

      var getCallCount = 0;
      when(() => mockBox.get('tickers')).thenAnswer((_) {
        getCallCount++;
        return expiredEntry.toMap();
      });
      when(() => mockBox.delete('tickers')).thenAnswer((_) async {});

      when(
        () => mockHttpClient.get(any()),
      ).thenThrow(Exception('Network Error'));

      // Act
      final result = await repository.fetchUniverse();

      // Assert
      expect(result, equals(['STALE.JK']));
      verify(() => mockBox.delete('tickers')).called(1);
      verify(() => mockHttpClient.get(any())).called(1);
    });

    test('throws error if network fails and no stale cache exists', () async {
      // Arrange
      when(() => mockBox.get('tickers')).thenReturn(null);
      when(
        () => mockHttpClient.get(any()),
      ).thenThrow(Exception('Network Error'));

      // Act & Assert
      try {
        await repository.fetchUniverse();
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isNotNull);
      }

      verify(() => mockHttpClient.get(any())).called(1);
    });
  });
}
