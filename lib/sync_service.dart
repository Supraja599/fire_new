import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'local_db.dart';
import 'services/apiservice.dart';

class SyncService {
  static bool _isSyncing = false;
  static StreamSubscription? _subscription;

  /// START LISTENING INTERNET
  static void init() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((result) {
      if (result != ConnectivityResult.none) {
        syncData();
      }
    });
  }

  /// MAIN SYNC FUNCTION
  static Future<void> syncData() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final pending = await LocalDB.getPending();

      for (var item in pending) {
        final id = item['id'];
        final data = item['data'].toString();

        final success = await ApiService.sendToServer(data);

        if (success) {
          await LocalDB.markSynced(id);
        }
      }
    } catch (e) {
      print("Sync error: $e");
    }

    _isSyncing = false;
  }

  /// CLEANUP (optional)
  static void dispose() {
    _subscription?.cancel();
  }
}