import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:http/http.dart' as http;
import 'tts_model_config.dart';

/// Native TTS engine using sherpa-onnx VITS.
///
/// Only available on iOS, Android, macOS, Windows, Linux.
class NativeTtsEngine {
  sherpa_onnx.OfflineTts? _tts;
  AudioPlayer? _player;
  String? _currentAudioPath;
  bool _isDownloading = false;

  void Function()? onComplete;

  Future<bool> isModelReady() async {
    return await TtsModelConfig.isModelDownloaded();
  }

  Future<void> initialize() async {
    sherpa_onnx.initBindings();

    final config = await TtsModelConfig.createConfig();
    _tts = sherpa_onnx.OfflineTts(config);

    _player = AudioPlayer();
    _player!.onPlayerComplete.listen((_) {
      onComplete?.call();
    });

    print('TTS Native: Initialized (sample rate: ${_tts!.sampleRate})');
  }

  Stream<double> downloadModel() async* {
    if (_isDownloading) return;
    _isDownloading = true;

    final modelPath = await TtsModelConfig.getModelPath();
    final modelDir = Directory(modelPath);

    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final archiveUrl = TtsModelConfig.modelArchiveUrl;
    final archivePath = '$modelPath/../${TtsModelConfig.modelDirName}.tar.bz2';

    print('TTS Native: Downloading model from $archiveUrl');

    try {
      final request = http.Request('GET', Uri.parse(archiveUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final file = File(archivePath);
      final sink = file.openWrite();

      int downloaded = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          yield downloaded / contentLength * 0.9;
        }
      }

      await sink.close();
      yield 0.92;

      print('TTS Native: Extracting model...');

      final result = await Process.run(
        'tar',
        ['-xjf', archivePath, '-C', '$modelPath/..'],
      );

      if (result.exitCode != 0) {
        throw Exception('Extract failed: ${result.stderr}');
      }

      await File(archivePath).delete();

      yield 1.0;
      print('TTS Native: Model ready');
    } catch (e) {
      print('TTS Native: Download error: $e');
      _isDownloading = false;
      rethrow;
    }

    _isDownloading = false;
  }

  Future<void> speak(String text, {double speed = 1.0}) async {
    if (_tts == null || _player == null) return;

    final audio = _tts!.generate(text: text, sid: 0, speed: speed);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentAudioPath = '${tempDir.path}/tts_$timestamp.wav';

    final success = sherpa_onnx.writeWave(
      filename: _currentAudioPath!,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );

    if (!success) {
      throw Exception('Failed to write audio');
    }

    await _player!.play(DeviceFileSource(_currentAudioPath!));
  }

  Future<void> stop() async {
    await _player?.stop();

    if (_currentAudioPath != null) {
      final file = File(_currentAudioPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentAudioPath = null;
    }
  }

  Future<void> pause() async {
    await _player?.pause();
  }

  Future<void> resume() async {
    await _player?.resume();
  }

  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume);
  }

  void dispose() {
    stop();
    _player?.dispose();
    _tts?.free();
  }
}
