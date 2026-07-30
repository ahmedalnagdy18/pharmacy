import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class SupplierModel extends Equatable {
  const SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.company,
    required this.notes,
  });
  final String id, name, phone, company, notes;
  SupplierModel copyWith({
    String? name,
    String? phone,
    String? company,
    String? notes,
  }) => SupplierModel(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    company: company ?? this.company,
    notes: notes ?? this.notes,
  );
  @override
  List<Object?> get props => [id, name, phone, company, notes];
}

class SupplierModelAdapter extends TypeAdapter<SupplierModel> {
  @override
  final int typeId = 7;
  @override
  SupplierModel read(BinaryReader r) {
    final c = r.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < c; i++) r.readByte(): r.read(),
    };
    return SupplierModel(
      id: f[0] as String,
      name: f[1] as String,
      phone: f[2] as String,
      company: (f[3] ?? '') as String,
      notes: (f[4] ?? '') as String,
    );
  }

  @override
  void write(BinaryWriter w, SupplierModel x) {
    w
      ..writeByte(5)
      ..writeByte(0)
      ..write(x.id)
      ..writeByte(1)
      ..write(x.name)
      ..writeByte(2)
      ..write(x.phone)
      ..writeByte(3)
      ..write(x.company)
      ..writeByte(4)
      ..write(x.notes);
  }
}
