// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TournamentModelAdapter extends TypeAdapter<TournamentModel> {
  @override
  final int typeId = 2;

  @override
  TournamentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TournamentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      teams: (fields[2] as List).cast<TeamModel>(),
      matches: (fields[3] as List).cast<MatchModel>(),
      matchTimerMinutes: fields[4] as int,
      statusIndex: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TournamentModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.teams)
      ..writeByte(3)
      ..write(obj.matches)
      ..writeByte(4)
      ..write(obj.matchTimerMinutes)
      ..writeByte(5)
      ..write(obj.statusIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
