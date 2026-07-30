import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class SaleType {
  SaleType._();

  static const direct = 'direct';
  static const representative = 'representative';
}

class SaleModel extends Equatable {
  const SaleModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.date,
    required this.saleType,
    required this.representativeId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.invoiceId,
    this.amountPaid,
  });

  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime date;
  final String saleType;
  final String? representativeId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? invoiceId;
  final double? amountPaid;

  SaleModel copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? total,
    DateTime? date,
    String? saleType,
    String? representativeId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? invoiceId,
    double? amountPaid,
  }) {
    return SaleModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      date: date ?? this.date,
      saleType: saleType ?? this.saleType,
      representativeId: representativeId ?? this.representativeId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      invoiceId: invoiceId ?? this.invoiceId,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    quantity,
    unitPrice,
    total,
    date,
    saleType,
    representativeId,
    customerId,
    customerName,
    customerPhone,
    invoiceId,
    amountPaid,
  ];
}

class SaleModelAdapter extends TypeAdapter<SaleModel> {
  @override
  final int typeId = 3;

  @override
  SaleModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return SaleModel(
      id: fields[0] as String,
      productId: fields[1] as String,
      quantity: fields[2] as int,
      unitPrice: fields[3] as double,
      total: fields[4] as double,
      date: fields[5] as DateTime,
      saleType: fields[6] as String,
      representativeId: fields[7] as String?,
      customerId: fields[8] as String?,
      customerName: fields[9] as String?,
      customerPhone: fields[10] as String?,
      invoiceId: fields[11] as String?,
      amountPaid: fields[12] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.saleType)
      ..writeByte(7)
      ..write(obj.representativeId)
      ..writeByte(8)
      ..write(obj.customerId)
      ..writeByte(9)
      ..write(obj.customerName)
      ..writeByte(10)
      ..write(obj.customerPhone)
      ..writeByte(11)
      ..write(obj.invoiceId)
      ..writeByte(12)
      ..write(obj.amountPaid);
  }
}
