import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'bubble_detector_service.dart';

class PdfAnalyzerService {
  /// Extrae imágenes de un PDF y las analiza con detección de burbujas
  Future<Map<String, dynamic>> analyzePdfWithQuestions(
    File pdfFile,
    List<String> questions,
  ) async {
    print("📄 [PdfAnalyzer] Iniciando análisis de PDF...");
    print("📄 [PdfAnalyzer] Archivo: ${pdfFile.path}");
    print("📄 [PdfAnalyzer] Cantidad de preguntas: ${questions.length}");
    
    try {
      // Cargar el PDF
      print("📄 [PdfAnalyzer] Abriendo documento PDF...");
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      print("📄 [PdfAnalyzer] ✅ PDF abierto. Páginas: $pageCount");

      // Procesar la primera página (donde está la prueba)
      if (pageCount == 0) {
        print("❌ [PdfAnalyzer] Error: El PDF no tiene páginas");
        throw Exception("El PDF no tiene páginas");
      }

      print("📄 [PdfAnalyzer] Obteniendo página 1...");
      final page = await document.getPage(1);
      print("📄 [PdfAnalyzer] ✅ Página obtenida");
      
      print("📄 [PdfAnalyzer] Renderizando página (alta resolución)...");
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      
      await page.close();
      
      if (pageImage == null || pageImage.bytes == null) {
        print("❌ [PdfAnalyzer] Error: No se pudo renderizar la página");
        throw Exception("No se pudo renderizar la página del PDF");
      }
      
      print("📄 [PdfAnalyzer] ✅ Página renderizada");
      print("📄 [PdfAnalyzer] Dimensiones: ${pageImage.width}x${pageImage.height}");
      print("📄 [PdfAnalyzer] Bytes extraídos: ${pageImage.bytes!.length} bytes");

      // Guardar temporalmente como imagen para análisis
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_pdf_page_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pageImage.bytes!);
      print("📄 [PdfAnalyzer] Imagen temporal: ${tempFile.path}");

      // Analizar con Detector de Burbujas
      print("📄 [PdfAnalyzer] Analizando con Detector de Burbujas...");
      final detector = BubbleDetectorService();
      final result = await detector.analyzeImage(tempFile, questions.length);
      
      // Limpiar
      await tempFile.delete();
      await document.close();
      
      print("📄 [PdfAnalyzer] ✅ Análisis completado");
      return result;
      
    } catch (e) {
      print("❌ [PdfAnalyzer] Error al procesar PDF: $e");
      print("❌ [PdfAnalyzer] Tipo de error: ${e.runtimeType}");
      rethrow;
    }
  }
}
