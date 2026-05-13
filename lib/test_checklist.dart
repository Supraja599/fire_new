import 'package:fire_new/local_db.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final list = await LocalDB.getModuleRecords(moduleCode: "co_detector", recordType: "checklist");
  if (list.isEmpty) {
    print("NO CHECKLIST FOUND FOR co_detector");
  } else {
    for (var item in list) {
      print("KEYS: ${item.keys.toList()}");
      print("DATA: $item");
    }
  }
}
