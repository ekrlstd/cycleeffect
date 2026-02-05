import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Configuration for the VITS-Piper TTS model.
///
/// Uses the high-quality Lessac voice (en_US-lessac-medium) which provides
/// natural-sounding speech suitable for traffic narration.
class TtsModelConfig {
  /// Model directory name
  static const String modelDirName = 'vits-piper-en_US-lessac-medium';

  /// Model filename
  static const String modelName = 'en_US-lessac-medium.onnx';

  /// Tokens filename
  static const String tokensName = 'tokens.txt';

  /// Data directory for espeak-ng phoneme data
  static const String dataDirName = 'espeak-ng-data';

  /// Model download URL (GitHub releases)
  static const String modelArchiveUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$modelDirName.tar.bz2';

  /// Model size in bytes (approximately)
  static const int modelSizeBytes = 64 * 1024 * 1024; // ~64MB

  /// Sample rate of the model output
  static const int sampleRate = 22050;

  /// Default speech speed (1.0 = normal)
  static const double defaultSpeed = 1.0;

  /// Gets the model directory path in documents
  static Future<String> getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/tts-models/$modelDirName';
  }

  /// Gets the espeak-ng data directory path
  static Future<String> getDataPath() async {
    final modelPath = await getModelPath();
    return '$modelPath/$dataDirName';
  }

  /// Checks if the model is downloaded and ready
  static Future<bool> isModelDownloaded() async {
    final modelPath = await getModelPath();
    final modelFile = File('$modelPath/$modelName');
    final tokensFile = File('$modelPath/$tokensName');
    final dataDir = Directory('$modelPath/$dataDirName');

    final modelExists = await modelFile.exists();
    final tokensExists = await tokensFile.exists();
    final dataExists = await dataDir.exists();

    if (modelExists && tokensExists && dataExists) {
      // Verify model file size (should be ~63MB)
      final size = await modelFile.length();
      return size > 50 * 1024 * 1024; // At least 50MB
    }

    return false;
  }

  /// Creates the sherpa-onnx TTS configuration
  static Future<sherpa_onnx.OfflineTtsConfig> createConfig() async {
    final modelPath = await getModelPath();
    final dataPath = await getDataPath();

    final vitsConfig = sherpa_onnx.OfflineTtsVitsModelConfig(
      model: '$modelPath/$modelName',
      tokens: '$modelPath/$tokensName',
      dataDir: dataPath,
      lexicon: '',
      dictDir: '',
    );

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      vits: vitsConfig,
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );

    return sherpa_onnx.OfflineTtsConfig(
      model: modelConfig,
      maxNumSenetences: 1,  // Note: typo in sherpa_onnx API
      ruleFsts: '',
      ruleFars: '',
    );
  }
}
