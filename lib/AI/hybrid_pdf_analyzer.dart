import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'hybrid_analyzer_service.dart';

/// Analizador de PDFs que usa el servicio híbrido (Gemini + OCR)
class HybridPdfAnalyzer {
  final HybridAnalyzerService _analyzer = HybridAnalyzerService();

  /// Analiza un archivo PDF usando el servicio híbrido
  Future<Map<String, dynamic>> analyzePdf(String pdfPath, int questionCount) async {
    print("📄🔵⚫ [HybridPdfAnalyzer] Iniciando análisis de PDF...");
    print("📄🔵⚫ [HybridPdfAnalyzer] Archivo: $pdfPath");
    
    File? tempImageFile;
    
    try {
      // 1. Abrir PDF
      print("📄 [HybridPdfAnalyzer] Abriendo PDF...");
      final document = await PdfDocument.openFile(pdfPath);
      
      print("📄 [HybridPdfAnalyzer] PDF abierto, páginas: ${document.pagesCount}");
      
      if (document.pagesCount == 0) {
        throw Exception("El PDF no tiene páginas");
      }
      
      // 2. Renderizar primera página
      print("📄 [HybridPdfAnalyzer] Renderizando primera página...");
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      
      if (pageImage == null) {
        throw Exception("No se pudo renderizar la página");
      }
      
      print("📄 [HybridPdfAnalyzer] ✅ Página renderizada: ${pageImage.width}x${pageImage.height}");
      
      // 3. Guardar imagen temporal
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_pdf_page.png';
      tempImageFile = File(tempPath);
      await tempImageFile.writeAsBytes(pageImage.bytes);
      
      print("📄 [HybridPdfAnalyzer] ✅ Imagen guardada: $tempPath");
      
      // 4. Analizar con servicio híbrido
      print("📄 [HybridPdfAnalyzer] Analizando con servicio híbrido...");
      final result = await _analyzer.analyzeImage(tempImageFile, questionCount);
      
      // 5. Limpiar
      await page.close();
      await tempImageFile.delete();
      
      print("📄 [HybridPdfAnalyzer] ✅ Análisis completado");
      return result;
      
    } catch (e) {
      print("❌ [HybridPdfAnalyzer] Error: $e");
      
      // Limpiar archivo temporal si existe
      if (tempImageFile != null && await tempImageFile.exists()) {
        await tempImageFile.delete();
      }
      
      rethrow;
    }
  }
}
