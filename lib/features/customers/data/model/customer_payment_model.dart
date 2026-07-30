import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class CustomerPaymentModel extends Equatable {
  const CustomerPaymentModel({
    required this.id,
    required this.customerId,
    required this.debtId,
    required this.amount,
    required this.date,
    required this.notes,
  });
  final String id, customerId, debtId, notes;
  final double amount;
  final DateTime date;
  @override
  List<Object?> get props => [id, customerId, debtId, amount, date, notes];
}

class CustomerPaymentModelAdapter extends TypeAdapter<CustomerPaymentModel> {
  @override
  final int typeId = 6;
  @override
  CustomerPaymentModel read(BinaryReader r) {
    final c = r.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < c; i++) r.readByte(): r.read(),
    };
    return CustomerPaymentModel(
      id: f[0] as String,
      customerId: f[1] as String,
      debtId: f[2] as String,
      amount: f[3] as double,
      date: f[4] as DateTime,
      notes: (f[5] ?? '') as String,
    );
  }

  @override
  void write(BinaryWriter w, CustomerPaymentModel x) {
    w
      ..writeByte(6)
      ..writeByte(0)
      ..write(x.id)
      ..writeByte(1)
      ..write(x.customerId)
      ..writeByte(2)
      ..write(x.debtId)
      ..writeByte(3)
      ..write(x.amount)
      ..writeByte(4)
      ..write(x.date)
      ..writeByte(5)
      ..write(x.notes);
  }
}
