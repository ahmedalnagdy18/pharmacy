import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class MedicineModel extends Equatable {
  const MedicineModel({
    required this.id,
    required this.name,
    required this.category,
    required this.barcode,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final String barcode;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;
  final String notes;
  final DateTime createdAt;

  MedicineModel copyWith({
    String? id,
    String? name,
    String? category,
    String? barcode,
    int? quantity,
    double? purchasePrice,
    double? sellingPrice,
    String? notes,
    DateTime? createdAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    barcode,
    quantity,
    purchasePrice,
    sellingPrice,
    notes,
    createdAt,
  ];
}

class MedicineModelAdapter extends TypeAdapter<MedicineModel> {
  @override
  final int typeId = 0;

  @override
  MedicineModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return MedicineModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      barcode: fields[3] as String,
      quantity: fields[4] as int,
      purchasePrice: fields[5] as double,
      sellingPrice: fields[6] as double,
      notes: fields[7] as String,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MedicineModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.purchasePrice)
      ..writeByte(6)
      ..write(obj.sellingPrice)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt);
  }
}
