import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/representative_inventory/domain/usecases/representative_inventory_usecases.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_state.dart';
import 'package:uuid/uuid.dart';

class RepresentativeInventoryCubit extends Cubit<RepresentativeInventoryState> {
  RepresentativeInventoryCubit({
    required this.getInventory,
    required this.assignInventory,
  }) : super(const RepresentativeInventoryInitial());

  final GetRepresentativeInventoryUseCase getInventory;
  final AssignRepresentativeInventoryUseCase assignInventory;
  final _uuid = const Uuid();

  Future<void> load() async {
    emit(const RepresentativeInventoryLoading());
    try {
      emit(RepresentativeInventoryLoaded(await getInventory()));
    } catch (error) {
      emit(RepresentativeInventoryError(error.toString()));
    }
  }

  Future<void> assign({
    required String representativeId,
    required String productId,
    required int quantity,
  }) async {
    emit(const RepresentativeInventoryLoading());
    try {
      await assignInventory(
        id: _uuid.v4(),
        representativeId: representativeId,
        productId: productId,
        quantity: quantity,
      );
      emit(RepresentativeInventoryLoaded(await getInventory()));
    } catch (error) {
      emit(RepresentativeInventoryError(error.toString()));
      await load();
    }
  }
}
