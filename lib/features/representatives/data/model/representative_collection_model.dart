import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class RepresentativeCollectionModel extends Equatable {
  const RepresentativeCollectionModel({required this.id, required this.representativeId, required this.invoiceId, required this.amount, required this.date, this.notes = ''});
  final String id, representativeId, invoiceId, notes;
  final double amount;
  final DateTime date;
  @override
  List<Object?> get props => [id, representativeId, invoiceId, amount, date, notes];
}

class RepresentativeCollectionModelAdapter extends TypeAdapter<RepresentativeCollectionModel> {
  @override final int typeId = 12;
  @override RepresentativeCollectionModel read(BinaryReader reader) {
    final count = reader.readByte();
    final f = <int, dynamic>{for (var i = 0; i < count; i++) reader.readByte(): reader.read()};
    return RepresentativeCollectionModel(id: f[0] as String, representativeId: f[1] as String, invoiceId: f[2] as String, amount: f[3] as double, date: f[4] as DateTime, notes: f[5] as String? ?? '');
  }
  @override void write(BinaryWriter writer, RepresentativeCollectionModel value) => writer
    ..writeByte(6)..writeByte(0)..write(value.id)..writeByte(1)..write(value.representativeId)
    ..writeByte(2)..write(value.invoiceId)..writeByte(3)..write(value.amount)
    ..writeByte(4)..write(value.date)..writeByte(5)..write(value.notes);
}
