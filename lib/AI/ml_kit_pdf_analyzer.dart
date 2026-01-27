import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'bubble_detector_service.dart';

class MlKitPdfAnalyzer {
  /// Analiza un PDF usando Detector de Burbujas
  Future<Map<String, dynamic>> analyzePdfWithQuestions(File pdfFile, int questionCount) async {
    print("📄 [MLKitPdfAnalyzer] Iniciando análisis...");
    print("📄 [MLKitPdfAnalyzer] PDF: ${pdfFile.path}");
    print("📄 [MLKitPdfAnalyzer] Preguntas: $questionCount");

    try {
      // Abrir PDF
      print("📄 [MLKitPdfAnalyzer] Abriendo PDF...");
      final document = await PdfDocument.openFile(pdfFile.path);
      print("📄 [MLKitPdfAnalyzer] ✅ PDF abierto. Páginas: ${document.pagesCount}");

      // Obtener primera página (donde suelen estar las respuestas)
      print("📄 [MLKitPdfAnalyzer] Renderizando primera página...");
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      print("📄 [MLKitPdfAnalyzer] ✅ Página renderizada");
      await page.close();

      if (pageImage == null || pageImage.bytes == null) {
        print("❌ [MLKitPdfAnalyzer] Error: no se pudo renderizar la página");
        throw Exception("No se pudo renderizar la página del PDF");
      }

      // Guardar imagen temporalmente
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_pdf_page.png');
      await tempFile.writeAsBytes(pageImage.bytes!);
      print("📄 [MLKitPdfAnalyzer] Imagen temporal: ${tempFile.path}");

      // Analizar con Detector de Burbujas
      print("📄 [MLKitPdfAnalyzer] Analizando con Detector de Burbujas...");
      final detectorService = BubbleDetectorService();
      final result = await detectorService.analyzeImage(tempFile, questionCount);

      // Limpiar archivo temporal
      await tempFile.delete();
      await document.close();

      print("📄 [MLKitPdfAnalyzer] ✅ Análisis completado");
      return result;

    } catch (e) {
      print("❌ [MLKitPdfAnalyzer] Error: $e");
      rethrow;
    }
  }
}
