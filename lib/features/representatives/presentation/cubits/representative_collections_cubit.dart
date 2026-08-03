import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/representatives/data/data_source/representative_collections_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_collection_model.dart';
import 'package:uuid/uuid.dart';

sealed class RepresentativeCollectionsState { const RepresentativeCollectionsState(); }
class RepresentativeCollectionsInitial extends RepresentativeCollectionsState { const RepresentativeCollectionsInitial(); }
class RepresentativeCollectionsLoading extends RepresentativeCollectionsState { const RepresentativeCollectionsLoading(); }
class RepresentativeCollectionsLoaded extends RepresentativeCollectionsState { const RepresentativeCollectionsLoaded(this.items); final List<RepresentativeCollectionModel> items; }
class RepresentativeCollectionsError extends RepresentativeCollectionsState { const RepresentativeCollectionsError(this.message); final String message; }

class RepresentativeCollectionsCubit extends Cubit<RepresentativeCollectionsState> {
  RepresentativeCollectionsCubit(this.source) : super(const RepresentativeCollectionsInitial());
  final RepresentativeCollectionsLocalDataSource source;
  Future<void> load() async { emit(const RepresentativeCollectionsLoading()); try { emit(RepresentativeCollectionsLoaded(await source.getAll())); } catch (e) { emit(RepresentativeCollectionsError(e.toString())); } }
  Future<void> collect({required String representativeId, required String invoiceId, required double amount, required double outstanding, String notes = ''}) async {
    try {
      if (!amount.isFinite || amount <= 0 || amount > outstanding) throw const AppException('Collection amount is invalid.');
      await source.save(RepresentativeCollectionModel(id: const Uuid().v4(), representativeId: representativeId, invoiceId: invoiceId, amount: amount, date: DateTime.now(), notes: notes.trim()));
      await load();
    } catch (e) { emit(RepresentativeCollectionsError(e.toString())); }
  }
}
