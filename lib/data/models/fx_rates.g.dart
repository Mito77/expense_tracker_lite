// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fx_rates.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FxRatesAdapter extends TypeAdapter<FxRates> {
  @override
  final int typeId = 1;

  @override
  FxRates read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FxRates(
      result: fields[0] as String,
      baseCode: fields[1] as String,
      lastUpdateUtc: fields[2] as DateTime,
      nextUpdateUtc: fields[3] as DateTime,
      rates: (fields[4] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, FxRates obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.result)
      ..writeByte(1)
      ..write(obj.baseCode)
      ..writeByte(2)
      ..write(obj.lastUpdateUtc)
      ..writeByte(3)
      ..write(obj.nextUpdateUtc)
      ..writeByte(4)
      ..write(obj.rates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FxRatesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
