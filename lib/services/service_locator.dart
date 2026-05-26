import 'package:get_it/get_it.dart';
import 'package:fire_new/services/equipment_repository.dart';

final GetIt locator = GetIt.instance;

void setupServiceLocator() {
  locator.registerLazySingleton<EquipmentRepository>(() => EquipmentRepository());
}
