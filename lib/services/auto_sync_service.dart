import 'dart:async';

import 'package:flutter/foundation.dart';

import 'db_service.dart';
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

  Future<void> start() async {

    /// 既に動作中

    if (_timer != null) {
      return;
    }

    /// =========================
    /// 設定取得
    /// =========================

    final enabled =
    await DbService.instance.getSetting(
      'auto_sync_enabled',
    );

    final minutesStr =
    await DbService.instance.getSetting(
      'auto_sync_minutes',
    );

    /// OFFなら開始しない

    if (enabled != 'true') {

      debugPrint(
        'AutoSync disabled',
      );

      return;
    }

    /// 間隔

    final minutes =
        int.tryParse(
          minutesStr ?? '60',
        ) ??
            60;

    debugPrint(
      'AutoSync started '
          '($minutes min)',
    );

    /// =========================
    /// Timer開始
    /// =========================

    _timer = Timer.periodic(

      Duration(minutes: minutes),

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
  /// 再起動
  /// 設定変更時用
  /// =========================

  Future<void> restart() async {

    stop();

    await start();
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