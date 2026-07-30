import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class SupplierDebtModel extends Equatable {
  const SupplierDebtModel({
    required this.id,
    required this.supplierId,
    required this.purchaseId,
    required this.invoiceTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.date,
  });
  final String id, supplierId, purchaseId, status;
  final double invoiceTotal, paidAmount, remainingAmount;
  final DateTime date;
  SupplierDebtModel copyWith({
    double? paidAmount,
    double? remainingAmount,
    String? status,
  }) => SupplierDebtModel(
    id: id,
    supplierId: supplierId,
    purchaseId: purchaseId,
    invoiceTotal: invoiceTotal,
    paidAmount: paidAmount ?? this.paidAmount,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    status: status ?? this.status,
    date: date,
  );
  @override
  List<Object?> get props => [
    id,
    supplierId,
    purchaseId,
    invoiceTotal,
    paidAmount,
    remainingAmount,
    status,
    date,
  ];
}

class SupplierDebtModelAdapter extends TypeAdapter<SupplierDebtModel> {
  @override
  final int typeId = 9;
  @override
  SupplierDebtModel read(BinaryReader r) {
    final c = r.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < c; i++) r.readByte(): r.read(),
    };
    return SupplierDebtModel(
      id: f[0] as String,
      supplierId: f[1] as String,
      purchaseId: f[2] as String,
      invoiceTotal: f[3] as double,
      paidAmount: f[4] as double,
      remainingAmount: f[5] as double,
      status: f[6] as String,
      date: f[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter w, SupplierDebtModel x) {
    w
      ..writeByte(8)
      ..writeByte(0)
      ..write(x.id)
      ..writeByte(1)
      ..write(x.supplierId)
      ..writeByte(2)
      ..write(x.purchaseId)
      ..writeByte(3)
      ..write(x.invoiceTotal)
      ..writeByte(4)
      ..write(x.paidAmount)
      ..writeByte(5)
      ..write(x.remainingAmount)
      ..writeByte(6)
      ..write(x.status)
      ..writeByte(7)
      ..write(x.date);
  }
}
