import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class PurchaseModel extends Equatable {
  const PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.total,
    required this.paidAmount,
    required this.date,
    this.invoiceId,
  });
  final String id, supplierId, productId;
  final String? invoiceId;
  final int quantity;
  final double unitCost, total, paidAmount;
  final DateTime date;

  PurchaseModel copyWith({double? paidAmount}) => PurchaseModel(
    id: id,
    supplierId: supplierId,
    productId: productId,
    quantity: quantity,
    unitCost: unitCost,
    total: total,
    paidAmount: paidAmount ?? this.paidAmount,
    date: date,
    invoiceId: invoiceId,
  );
  @override
  List<Object?> get props => [
    id,
    supplierId,
    productId,
    quantity,
    unitCost,
    total,
    paidAmount,
    date,
    invoiceId,
  ];
}

class PurchaseModelAdapter extends TypeAdapter<PurchaseModel> {
  @override
  final int typeId = 8;
  @override
  PurchaseModel read(BinaryReader r) {
    final c = r.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < c; i++) r.readByte(): r.read(),
    };
    return PurchaseModel(
      id: f[0] as String,
      supplierId: f[1] as String,
      productId: f[2] as String,
      quantity: f[3] as int,
      unitCost: f[4] as double,
      total: f[5] as double,
      paidAmount: f[6] as double,
      date: f[7] as DateTime,
      invoiceId: f[8] as String?,
    );
  }

  @override
  void write(BinaryWriter w, PurchaseModel x) {
    w
      ..writeByte(9)
      ..writeByte(0)
      ..write(x.id)
      ..writeByte(1)
      ..write(x.supplierId)
      ..writeByte(2)
      ..write(x.productId)
      ..writeByte(3)
      ..write(x.quantity)
      ..writeByte(4)
      ..write(x.unitCost)
      ..writeByte(5)
      ..write(x.total)
      ..writeByte(6)
      ..write(x.paidAmount)
      ..writeByte(7)
      ..write(x.date)
      ..writeByte(8)
      ..write(x.invoiceId);
  }
}
