import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class DebtStatus {
  DebtStatus._();
  static const pending = 'Pending';
  static const paid = 'Paid';
}

class CustomerDebtModel extends Equatable {
  const CustomerDebtModel({
    required this.id,
    required this.customerId,
    required this.invoiceId,
    required this.invoiceTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, customerId, invoiceId, status;
  final double invoiceTotal, paidAmount, remainingAmount;
  final DateTime createdAt, updatedAt;
  CustomerDebtModel copyWith({
    double? paidAmount,
    double? remainingAmount,
    String? status,
    DateTime? updatedAt,
  }) => CustomerDebtModel(
    id: id,
    customerId: customerId,
    invoiceId: invoiceId,
    invoiceTotal: invoiceTotal,
    paidAmount: paidAmount ?? this.paidAmount,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  @override
  List<Object?> get props => [
    id,
    customerId,
    invoiceId,
    invoiceTotal,
    paidAmount,
    remainingAmount,
    status,
    createdAt,
    updatedAt,
  ];
}

class CustomerDebtModelAdapter extends TypeAdapter<CustomerDebtModel> {
  @override
  final int typeId = 5;
  @override
  CustomerDebtModel read(BinaryReader r) {
    final c = r.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < c; i++) r.readByte(): r.read(),
    };
    return CustomerDebtModel(
      id: f[0] as String,
      customerId: f[1] as String,
      invoiceId: f[2] as String,
      invoiceTotal: f[3] as double,
      paidAmount: f[4] as double,
      remainingAmount: f[5] as double,
      status: f[6] as String,
      createdAt: f[7] as DateTime,
      updatedAt: f[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter w, CustomerDebtModel x) {
    w
      ..writeByte(9)
      ..writeByte(0)
      ..write(x.id)
      ..writeByte(1)
      ..write(x.customerId)
      ..writeByte(2)
      ..write(x.invoiceId)
      ..writeByte(3)
      ..write(x.invoiceTotal)
      ..writeByte(4)
      ..write(x.paidAmount)
      ..writeByte(5)
      ..write(x.remainingAmount)
      ..writeByte(6)
      ..write(x.status)
      ..writeByte(7)
      ..write(x.createdAt)
      ..writeByte(8)
      ..write(x.updatedAt);
  }
}
