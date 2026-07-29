import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class RepresentativeModel extends Equatable {
  const RepresentativeModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  RepresentativeModel copyWith({
    String? id,
    String? name,
    String? phone,
  }) {
    return RepresentativeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [id, name, phone];
}

class RepresentativeModelAdapter extends TypeAdapter<RepresentativeModel> {
  @override
  final int typeId = 1;

  @override
  RepresentativeModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return RepresentativeModel(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RepresentativeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone);
  }
}
