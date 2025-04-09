// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class GermanNounHiveAdapter extends TypeAdapter<GermanNounHive> {
  @override
  final int typeId = 0;

  @override
  GermanNounHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GermanNounHive(
      id: fields[0] as String,
      noun: fields[1] as String,
      article: fields[2] as String,
      plural: fields[3] == null ? '' : fields[3] as String,
      english: fields[4] == null ? '' : fields[4] as String,
      difficulty: (fields[5] as num).toInt(),
      updatedAt: fields[6] as DateTime,
      version: (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, GermanNounHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.noun)
      ..writeByte(2)
      ..write(obj.article)
      ..writeByte(3)
      ..write(obj.plural)
      ..writeByte(4)
      ..write(obj.english)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GermanNounHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
