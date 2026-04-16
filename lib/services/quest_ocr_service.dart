import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class QuestOcrService {
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);

    try {
      final recognizedText = await recognizer.processImage(inputImage);
      return _normalizeText(recognizedText.text);
    } finally {
      await recognizer.close();
    }
  }

  String _normalizeText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
