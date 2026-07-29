import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class RepresentativeInventoryModel extends Equatable {
  const RepresentativeInventoryModel({
    required this.id,
    required this.representativeId,
    required this.productId,
    required this.quantityAssigned,
    required this.quantitySold,
  });

  final String id;
  final String representativeId;
  final String productId;
  final int quantityAssigned;
  final int quantitySold;

  int get remainingQuantity => quantityAssigned - quantitySold;

  RepresentativeInventoryModel copyWith({
    String? id,
    String? representativeId,
    String? productId,
    int? quantityAssigned,
    int? quantitySold,
  }) {
    return RepresentativeInventoryModel(
      id: id ?? this.id,
      representativeId: representativeId ?? this.representativeId,
      productId: productId ?? this.productId,
      quantityAssigned: quantityAssigned ?? this.quantityAssigned,
      quantitySold: quantitySold ?? this.quantitySold,
    );
  }

  @override
  List<Object?> get props => [
    id,
    representativeId,
    productId,
    quantityAssigned,
    quantitySold,
  ];
}

class RepresentativeInventoryModelAdapter
    extends TypeAdapter<RepresentativeInventoryModel> {
  @override
  final int typeId = 2;

  @override
  RepresentativeInventoryModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return RepresentativeInventoryModel(
      id: fields[0] as String,
      representativeId: fields[1] as String,
      productId: fields[2] as String,
      quantityAssigned: fields[3] as int,
      quantitySold: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RepresentativeInventoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.representativeId)
      ..writeByte(2)
      ..write(obj.productId)
      ..writeByte(3)
      ..write(obj.quantityAssigned)
      ..writeByte(4)
      ..write(obj.quantitySold);
  }
}
