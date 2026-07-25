/*
===========================================
ZSOLT PRO AI
Build: #017
Version: v1.0.0
File: api_rate_limiter.dart
===========================================
*/

import 'dart:async';
import 'dart:collection';

class ApiRateLimiter {
  ApiRateLimiter._();

  static final ApiRateLimiter instance = ApiRateLimiter._();

  /// Minimum várakozás két API kérés között
  static const Duration requestInterval = Duration(seconds: 1);

  final Queue<_QueuedRequest> _queue = Queue<_QueuedRequest>();

  bool _running = false;
  DateTime? _lastRequestTime;

  /// API kérés végrehajtása sorba állítva
  Future<T> execute<T>(
    Future<T> Function() action,
  ) {
    final completer = Completer<T>();

    _queue.add(
      _QueuedRequest(
        () async {
          try {
            final result = await action();
            completer.complete(result);
          } catch (e, s) {
            completer.completeError(e, s);
          }
        },
      ),
    );

    _processQueue();

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_running) return;

    _running = true;

    while (_queue.isNotEmpty) {
      final now = DateTime.now();

      if (_lastRequestTime != null) {
        final elapsed = now.difference(_lastRequestTime!);

        if (elapsed < requestInterval) {
          await Future.delayed(
            requestInterval - elapsed,
          );
        }
      }

      final request = _queue.removeFirst();

      _lastRequestTime = DateTime.now();

      await request.run();
    }

    _running = false;
  }

  /// Sorban várakozó API hívások száma
  int get pendingRequests => _queue.length;

  /// Dolgozik-e jelenleg
  bool get isRunning => _running;

  /// Queue ürítése
  void clearQueue() {
    _queue.clear();
  }
}

class _QueuedRequest {
  final Future<void> Function() run;

  _QueuedRequest(this.run);
}
