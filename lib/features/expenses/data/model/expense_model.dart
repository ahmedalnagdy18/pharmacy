import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class ExpenseModel extends Equatable {
  const ExpenseModel({required this.id, required this.amount, required this.reason, required this.date});
  final String id;
  final double amount;
  final String reason;
  final DateTime date;

  @override
  List<Object?> get props => [id, amount, reason, date];
}

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 11;
  @override
  ExpenseModel read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{for (var i = 0; i < count; i++) reader.readByte(): reader.read()};
    return ExpenseModel(id: fields[0] as String, amount: fields[1] as double, reason: fields[2] as String, date: fields[3] as DateTime);
  }
  @override
  void write(BinaryWriter writer, ExpenseModel value) => writer
    ..writeByte(4)..writeByte(0)..write(value.id)
    ..writeByte(1)..write(value.amount)
    ..writeByte(2)..write(value.reason)
    ..writeByte(3)..write(value.date);
}
