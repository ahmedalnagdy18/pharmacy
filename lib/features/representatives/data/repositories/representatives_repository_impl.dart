import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/representatives/data/data_source/representatives_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/domain/repositories/representatives_repository.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/data_source/representative_collections_local_data_source.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';

class RepresentativesRepositoryImpl implements RepresentativesRepository {
  const RepresentativesRepositoryImpl(
    this.localDataSource, {
    required this.inventoryDataSource,
    required this.salesDataSource,
    required this.collectionsDataSource,
  });

  final RepresentativesLocalDataSource localDataSource;
  final RepresentativeInventoryLocalDataSource inventoryDataSource;
  final SalesLocalDataSource salesDataSource;
  final RepresentativeCollectionsLocalDataSource collectionsDataSource;

  @override
  Future<List<RepresentativeModel>> getRepresentatives() {
    return localDataSource.getAll();
  }

  @override
  Future<RepresentativeModel?> getRepresentativeById(String id) {
    return localDataSource.getById(id);
  }

  @override
  Future<void> saveRepresentative(RepresentativeModel representative) {
    if (representative.name.trim().isEmpty) {
      throw const AppException('Representative name is required.');
    }
    if (representative.phone.trim().isEmpty) {
      throw const AppException('Phone is required.');
    }
    return localDataSource.save(representative);
  }

  @override
  Future<void> deleteRepresentative(String id) async {
    final hasInventory = (await inventoryDataSource.getAll()).any(
      (item) => item.representativeId == id,
    );
    final hasSales = (await salesDataSource.getAll()).any(
      (item) => item.representativeId == id,
    );
    final hasCollections = (await collectionsDataSource.getAll()).any(
      (item) => item.representativeId == id,
    );
    if (hasInventory || hasSales || hasCollections) {
      throw const AppException(
        'Representatives with inventory, sales, or collections cannot be deleted.',
      );
    }
    await localDataSource.delete(id);
  }
}
