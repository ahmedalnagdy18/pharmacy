import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/domain/usecases/product_usecases.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:uuid/uuid.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({
    required this.getProducts,
    required this.saveProduct,
    required this.deleteProduct,
  }) : super(const ProductsInitial());

  final GetProductsUseCase getProducts;
  final SaveProductUseCase saveProduct;
  final DeleteProductUseCase deleteProduct;
  final _uuid = const Uuid();

  Future<void> load() async {
    emit(const ProductsLoading());
    try {
      emit(ProductsLoaded(await getProducts()));
    } catch (error) {
      emit(ProductsError(error.toString()));
    }
  }

  Future<void> createOrUpdate({
    String? id,
    required String name,
    required String category,
    required String barcode,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
    required String notes,
    DateTime? createdAt,
  }) async {
    emit(const ProductsLoading());
    try {
      await saveProduct(
        MedicineModel(
          id: id ?? _uuid.v4(),
          name: name.trim(),
          category: category.trim(),
          barcode: barcode.trim(),
          quantity: quantity,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          notes: notes.trim(),
          createdAt: createdAt ?? DateTime.now(),
        ),
      );
      emit(ProductsLoaded(await getProducts()));
    } catch (error) {
      emit(ProductsError(error.toString()));
      await load();
    }
  }

  Future<void> remove(String id) async {
    emit(const ProductsLoading());
    try {
      await deleteProduct(id);
      emit(ProductsLoaded(await getProducts()));
    } catch (error) {
      emit(ProductsError(error.toString()));
      await load();
    }
  }
}
