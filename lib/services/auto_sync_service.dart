import 'dart:async';

import 'package:flutter/foundation.dart';

import 'sync_service.dart';

class AutoSyncService {

  static final AutoSyncService instance =
  AutoSyncService._();

  AutoSyncService._();

  Timer? _timer;

  bool _running = false;

  /// =========================
  /// 開始
  /// =========================

  void start() {

    if (_timer != null) {
      return;
    }

    debugPrint(
      'AutoSync started',
    );

    _timer = Timer.periodic(
      const Duration(hours: 1),

          (_) async {

        if (_running) {
          return;
        }

        _running = true;

        try {

          debugPrint(
            'AutoSync syncing...',
          );

          await SyncService().sync();

          debugPrint(
            'AutoSync complete',
          );

        } catch (e) {

          debugPrint(
            'AutoSync error: $e',
          );

        } finally {

          _running = false;
        }
      },
    );
  }

  /// =========================
  /// 停止
  /// =========================

  void stop() {

    debugPrint(
      'AutoSync stopped',
    );

    _timer?.cancel();

    _timer = null;
  }
}