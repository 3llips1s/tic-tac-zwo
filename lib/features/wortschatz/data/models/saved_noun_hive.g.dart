// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_noun_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedNounHiveAdapter extends TypeAdapter<SavedNounHive> {
  @override
  final typeId = 1;

  @override
  SavedNounHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedNounHive(
      id: fields[0] as String,
      article: fields[1] as String,
      noun: fields[2] as String,
      plural: fields[3] == null ? '' : fields[3] as String,
      english: fields[4] == null ? '' : fields[4] as String,
      savedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedNounHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.article)
      ..writeByte(2)
      ..write(obj.noun)
      ..writeByte(3)
      ..write(obj.plural)
      ..writeByte(4)
      ..write(obj.english)
      ..writeByte(5)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedNounHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
