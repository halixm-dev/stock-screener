import 'package:hive/hive.dart';
import '../../domain/ohlcv_data.dart'; // For SignalType
import '../../domain/signal_engine.dart'; // For FreshCheckResult

enum SignalTypeHive { buy, sell, neutral }

extension SignalTypeMapper on SignalType {
  SignalTypeHive toHive() {
    switch (this) {
      case SignalType.buy:
        return SignalTypeHive.buy;
      case SignalType.sell:
        return SignalTypeHive.sell;
      case SignalType.neutral:
        return SignalTypeHive.neutral;
    }
  }
}

extension SignalTypeHiveMapper on SignalTypeHive {
  SignalType toDomain() {
    switch (this) {
      case SignalTypeHive.buy:
        return SignalType.buy;
      case SignalTypeHive.sell:
        return SignalType.sell;
      case SignalTypeHive.neutral:
        return SignalType.neutral;
    }
  }
}

class SignalTypeHiveAdapter extends TypeAdapter<SignalTypeHive> {
  @override
  final int typeId = 1;

  @override
  SignalTypeHive read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SignalTypeHive.buy;
      case 1:
        return SignalTypeHive.sell;
      case 2:
        return SignalTypeHive.neutral;
      default:
        return SignalTypeHive.neutral;
    }
  }

  @override
  void write(BinaryWriter writer, SignalTypeHive obj) {
    switch (obj) {
      case SignalTypeHive.buy:
        writer.writeByte(0);
        break;
      case SignalTypeHive.sell:
        writer.writeByte(1);
        break;
      case SignalTypeHive.neutral:
        writer.writeByte(2);
        break;
    }
  }
}

class ScreenResult {
  final String symbol;
  final SignalTypeHive signal;
  final double price;
  final double changePercent;
  final DateTime timestamp;
  final FreshCheckResultHive freshResult;

  const ScreenResult({
    required this.symbol,
    required this.signal,
    required this.price,
    required this.changePercent,
    required this.timestamp,
    this.freshResult = FreshCheckResultHive.staleRepeat,
  });

  bool get isFresh => freshResult == FreshCheckResultHive.fresh;
}

class ScreenResultAdapter extends TypeAdapter<ScreenResult> {
  @override
  final int typeId = 2;

  @override
  ScreenResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle migration from old `bool isFresh` at index 5
    FreshCheckResultHive getFreshResult() {
      if (fields.containsKey(6)) {
        return fields[6] as FreshCheckResultHive;
      }
      if (fields.containsKey(5)) {
        final bool isFreshOld = fields[5] as bool? ?? false;
        return isFreshOld
            ? FreshCheckResultHive.fresh
            : FreshCheckResultHive.staleRepeat;
      }
      return FreshCheckResultHive.staleRepeat;
    }

    return ScreenResult(
      symbol: fields[0] as String,
      signal: fields[1] as SignalTypeHive,
      price: fields[2] as double,
      changePercent: fields[3] as double,
      timestamp: fields[4] as DateTime,
      freshResult: getFreshResult(),
    );
  }

  @override
  void write(BinaryWriter writer, ScreenResult obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.symbol);
    writer.writeByte(1);
    writer.write(obj.signal);
    writer.writeByte(2);
    writer.write(obj.price);
    writer.writeByte(3);
    writer.write(obj.changePercent);
    writer.writeByte(4);
    writer.write(obj.timestamp);
    writer.writeByte(5);
    writer.write(
      obj.isFresh,
    ); // Keep old bool at index 5 for backward compatibility reading by old app versions? Actually, just write it.
    writer.writeByte(6);
    writer.write(obj.freshResult);
  }
}

enum FreshCheckResultHive { fresh, staleRepeat, insufficientHistory }

extension FreshCheckResultMapper on FreshCheckResult {
  FreshCheckResultHive toHive() {
    switch (this) {
      case FreshCheckResult.fresh:
        return FreshCheckResultHive.fresh;
      case FreshCheckResult.staleRepeat:
        return FreshCheckResultHive.staleRepeat;
      case FreshCheckResult.insufficientHistory:
        return FreshCheckResultHive.insufficientHistory;
    }
  }
}

extension FreshCheckResultHiveMapper on FreshCheckResultHive {
  FreshCheckResult toDomain() {
    switch (this) {
      case FreshCheckResultHive.fresh:
        return FreshCheckResult.fresh;
      case FreshCheckResultHive.staleRepeat:
        return FreshCheckResult.staleRepeat;
      case FreshCheckResultHive.insufficientHistory:
        return FreshCheckResult.insufficientHistory;
    }
  }
}

class FreshCheckResultHiveAdapter extends TypeAdapter<FreshCheckResultHive> {
  @override
  final int typeId = 3;

  @override
  FreshCheckResultHive read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FreshCheckResultHive.fresh;
      case 1:
        return FreshCheckResultHive.staleRepeat;
      case 2:
        return FreshCheckResultHive.insufficientHistory;
      default:
        return FreshCheckResultHive.staleRepeat;
    }
  }

  @override
  void write(BinaryWriter writer, FreshCheckResultHive obj) {
    switch (obj) {
      case FreshCheckResultHive.fresh:
        writer.writeByte(0);
        break;
      case FreshCheckResultHive.staleRepeat:
        writer.writeByte(1);
        break;
      case FreshCheckResultHive.insufficientHistory:
        writer.writeByte(2);
        break;
    }
  }
}
