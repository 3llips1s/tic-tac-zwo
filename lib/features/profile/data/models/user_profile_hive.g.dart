// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileHiveAdapter extends TypeAdapter<UserProfileHive> {
  @override
  final typeId = 2;

  @override
  UserProfileHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileHive(
      id: fields[0] as String,
      username: fields[1] as String,
      points: (fields[2] as num).toInt(),
      gamesPlayed: (fields[3] as num).toInt(),
      gamesWon: (fields[4] as num).toInt(),
      gamesDrawn: (fields[5] as num).toInt(),
      lat: (fields[6] as num?)?.toDouble(),
      lng: (fields[7] as num?)?.toDouble(),
      lastOnline: fields[8] as DateTime,
      isOnline: fields[9] as bool,
      avatarUrl: fields[10] as String?,
      countryCode: fields[11] as String?,
      totalArticleAttempts: (fields[12] as num).toInt(),
      totalCorrectArticles: (fields[13] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileHive obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.gamesPlayed)
      ..writeByte(4)
      ..write(obj.gamesWon)
      ..writeByte(5)
      ..write(obj.gamesDrawn)
      ..writeByte(6)
      ..write(obj.lat)
      ..writeByte(7)
      ..write(obj.lng)
      ..writeByte(8)
      ..write(obj.lastOnline)
      ..writeByte(9)
      ..write(obj.isOnline)
      ..writeByte(10)
      ..write(obj.avatarUrl)
      ..writeByte(11)
      ..write(obj.countryCode)
      ..writeByte(12)
      ..write(obj.totalArticleAttempts)
      ..writeByte(13)
      ..write(obj.totalCorrectArticles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
