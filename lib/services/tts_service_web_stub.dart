/// Web stub for NativeTtsEngine.
///
/// On web, sherpa-onnx is not available, so this stub provides
/// a no-op implementation that the TtsService can safely instantiate
/// but will never actually use (due to kIsWeb checks).
class NativeTtsEngine {
  void Function()? onComplete;

  Future<bool> isModelReady() async => false;

  Future<void> initialize() async {}

  Stream<double> downloadModel() async* {
    yield 1.0;
  }

  Future<void> speak(String text, {double speed = 1.0}) async {}

  Future<void> stop() async {}

  Future<void> pause() async {}

  Future<void> resume() async {}

  Future<void> setVolume(double volume) async {}

  void dispose() {}
}
