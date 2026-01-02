import 'package:flutter/services.dart';

class DockProgress {
  DockProgress._();
  static final instance = DockProgress._();

  final _methodChannel = const MethodChannel('dock_progress');

  Future<void> start() async {
    return await _methodChannel.invokeMethod<void>('start');
  }

  Future<void> stop() async {
    return await _methodChannel.invokeMethod<void>('stop');
  }
}
