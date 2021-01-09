// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_classes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreablePostDataAdapter extends TypeAdapter<StoreablePostData> {
  @override
  final int typeId = 0;

  @override
  StoreablePostData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreablePostData(
      postID: fields[0] as int,
      clicks: fields[1] as int,
      lastClickTime: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StoreablePostData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.postID)
      ..writeByte(1)
      ..write(obj.clicks)
      ..writeByte(2)
      ..write(obj.lastClickTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreablePostDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
