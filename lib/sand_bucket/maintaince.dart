import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class SandBucketMaintenancePage extends StatelessWidget {
  const SandBucketMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Sand Bucket Maintenance",
      imagePath: "assets/sand_bucket.png",
      api: ModuleApiService.sandBucket,
    );
  }
}
