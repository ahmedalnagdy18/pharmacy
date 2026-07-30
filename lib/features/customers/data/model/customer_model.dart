import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class CustomerModel extends Equatable {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.createdAt,
  });
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final DateTime createdAt;
  CustomerModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? notes,
  }) => CustomerModel(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );
  @override
  List<Object?> get props => [id, name, phone, address, notes, createdAt];
}

class CustomerModelAdapter extends TypeAdapter<CustomerModel> {
  @override
  final int typeId = 4;
  @override
  CustomerModel read(BinaryReader reader) {
    final count = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return CustomerModel(
      id: f[0] as String,
      name: f[1] as String,
      phone: f[2] as String,
      address: (f[3] ?? '') as String,
      notes: (f[4] ?? '') as String,
      createdAt: f[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerModel value) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(value.id)
      ..writeByte(1)
      ..write(value.name)
      ..writeByte(2)
      ..write(value.phone)
      ..writeByte(3)
      ..write(value.address)
      ..writeByte(4)
      ..write(value.notes)
      ..writeByte(5)
      ..write(value.createdAt);
  }
}
