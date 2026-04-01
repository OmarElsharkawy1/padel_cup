// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchModelAdapter extends TypeAdapter<MatchModel> {
  @override
  final int typeId = 1;

  @override
  MatchModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchModel(
      id: fields[0] as String,
      roundNumber: fields[1] as int,
      courtNumber: fields[2] as int,
      team1Id: fields[3] as String,
      team2Id: fields[4] as String,
      team1Sets: fields[5] as int,
      team2Sets: fields[6] as int,
      isCompleted: fields[7] as bool,
      groupId: fields[8] as String,
      isFinal: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MatchModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.roundNumber)
      ..writeByte(2)
      ..write(obj.courtNumber)
      ..writeByte(3)
      ..write(obj.team1Id)
      ..writeByte(4)
      ..write(obj.team2Id)
      ..writeByte(5)
      ..write(obj.team1Sets)
      ..writeByte(6)
      ..write(obj.team2Sets)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.groupId)
      ..writeByte(9)
      ..write(obj.isFinal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
