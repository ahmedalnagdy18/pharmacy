import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/domain/usecases/representative_usecases.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_state.dart';
import 'package:uuid/uuid.dart';

class RepresentativesCubit extends Cubit<RepresentativesState> {
  RepresentativesCubit({
    required this.getRepresentatives,
    required this.saveRepresentative,
    required this.deleteRepresentative,
  }) : super(const RepresentativesInitial());

  final GetRepresentativesUseCase getRepresentatives;
  final SaveRepresentativeUseCase saveRepresentative;
  final DeleteRepresentativeUseCase deleteRepresentative;
  final _uuid = const Uuid();

  Future<void> load() async {
    emit(const RepresentativesLoading());
    try {
      emit(RepresentativesLoaded(await getRepresentatives()));
    } catch (error) {
      emit(RepresentativesError(error.toString()));
    }
  }

  Future<void> createOrUpdate({
    String? id,
    required String name,
    required String phone,
  }) async {
    emit(const RepresentativesLoading());
    try {
      await saveRepresentative(
        RepresentativeModel(
          id: id ?? _uuid.v4(),
          name: name.trim(),
          phone: phone.trim(),
        ),
      );
      emit(RepresentativesLoaded(await getRepresentatives()));
    } catch (error) {
      emit(RepresentativesError(error.toString()));
      await load();
    }
  }

  Future<void> remove(String id) async {
    emit(const RepresentativesLoading());
    try {
      await deleteRepresentative(id);
      emit(RepresentativesLoaded(await getRepresentatives()));
    } catch (error) {
      emit(RepresentativesError(error.toString()));
      await load();
    }
  }
}
