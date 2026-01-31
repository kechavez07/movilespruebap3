import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'hybrid_analyzer_service.dart';
import 'image_preprocessor.dart';

/// 📄 Servicio especializado para analizar PDFs directamente
/// Intenta extraer texto del PDF sin conversión a imagen
class PdfAnalyzerService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  late final HybridAnalyzerService _hybridAnalyzer;

  PdfAnalyzerService() {
    _hybridAnalyzer = HybridAnalyzerService();
  }

  /// Analiza un PDF completo extrayendo respuestas
  Future<Map<String, dynamic>> analyzePdf(
    File pdfFile,
    int questionCount,
  ) async {
    print("\n📄 [PdfAnalyzer] ========== INICIANDO ANÁLISIS DE PDF ==========");
    print("📄 [PdfAnalyzer] Archivo: ${pdfFile.path}");
    
    // Verificación inicial del archivo
    if (!pdfFile.existsSync()) {
      print("❌ [PdfAnalyzer] ❌ ARCHIVO NO EXISTE");
      return {'studentName': '', 'answers': [], 'error': 'Archivo no encontrado'};
    }
    
    final fileSize = await pdfFile.length();
    print("📄 [PdfAnalyzer] Tamaño del PDF: $fileSize bytes");
    
    if (fileSize == 0) {
      print("❌ [PdfAnalyzer] ❌ PDF VACÍO");
      return {'studentName': '', 'answers': [], 'error': 'PDF vacío'};
    }

    print("📄 [PdfAnalyzer] Preguntas esperadas: $questionCount\n");

    try {
      // PASO 1: Intentar estrategia 1 - Convertir a imagen de ALTA resolución
      print("📄 [PdfAnalyzer] INTENTO 1: Conversión a imagen (2400x3200 - Alta resolución)");
      final result1 = await _analyzeViaHighResImage(pdfFile, questionCount);
      
      if ((result1['answers'] as List).isNotEmpty) {
        print("✅ [PdfAnalyzer] ✅ ¡Éxito en INTENTO 1! Encontradas ${(result1['answers'] as List).length} respuestas");
        await textRecognizer.close();
        return result1;
      }

      print("⚠️  [PdfAnalyzer] INTENTO 1 falló (0 respuestas detectadas)\n");

      // PASO 2: Intentar estrategia 2 - Convertir a imagen con resolución estándar
      print("📄 [PdfAnalyzer] INTENTO 2: Conversión a imagen (1200x1600 - Resolución estándar)");
      final result2 = await _analyzeViaStandardImage(pdfFile, questionCount);
      
      if ((result2['answers'] as List).isNotEmpty) {
        print("✅ [PdfAnalyzer] ✅ ¡Éxito en INTENTO 2! Encontradas ${(result2['answers'] as List).length} respuestas");
        await textRecognizer.close();
        return result2;
      }

      print("⚠️  [PdfAnalyzer] INTENTO 2 falló (0 respuestas detectadas)\n");

      // PASO 3: Retornar resultado vacío con advertencia
      print("❌ [PdfAnalyzer] ❌ Todos los intentos fallaron. Retornando resultado vacío.\n");
      print("📄 [PdfAnalyzer] ℹ️ ANÁLISIS DE CAUSAS:");
      print("📄 [PdfAnalyzer]   1. El PDF podría ser una imagen escaneada sin texto embebido");
      print("📄 [PdfAnalyzer]   2. El texto podría no estar en formato latino (verificar idioma)");
      print("📄 [PdfAnalyzer]   3. La imagen convertida tiene calidad demasiado baja");
      print("📄 [PdfAnalyzer]   4. El PDF podría estar protegido o corrupto");
      print("📄 [PdfAnalyzer]   5. El contraste de la imagen es insuficiente para OCR\n");

      await textRecognizer.close();
      return {
        'studentName': '',
        'answers': [],
        'error': 'No se pudo extraer texto del PDF',
      };
    } catch (e) {
      print("❌ [PdfAnalyzer] Excepción fatal: $e");
      print("❌ [PdfAnalyzer] Stack: ${StackTrace.current}");
      await textRecognizer.close();
      return {
        'studentName': '',
        'answers': [],
        'error': e.toString(),
      };
    }
  }

  /// Estrategia 1: Conversión a imagen de ALTA resolución
  Future<Map<String, dynamic>> _analyzeViaHighResImage(
    File pdfFile,
    int questionCount,
  ) async {
    File? tempImage;
    File? enhancedImage;
    try {
      print("  📊 Abriendo PDF...");
      final document = await PdfDocument.openFile(pdfFile.path);
      print("  ✅ PDF abierto exitosamente");
      print("  📊 Total de páginas: ${document.pagesCount}");
      
      final page = await document.getPage(1);
      print("  ✅ Página 1 obtenida correctamente");

      print("  📊 Renderizando a 2400x3200 (calidad ultra)...");
      final image = await page.render(width: 2400, height: 3200);

      if (image == null) {
        print("  ❌ ERROR: page.render() retornó NULL");
        throw Exception("Render retornó NULL");
      }

      print("  ✅ Renderizado completado");
      print("  📊 Dimensiones: ${image.width}x${image.height}");
      print("  📊 Bytes generados: ${image.bytes.length}");

      // Guardar temporalmente
      final tempDir = Directory.systemTemp;
      tempImage = File('${tempDir.path}/pdf_ultra_${DateTime.now().millisecondsSinceEpoch}.png');
      print("  📊 Guardando imagen temporal en: ${tempImage.path}");
      
      await tempImage.writeAsBytes(image.bytes);
      print("  ✅ Archivo escrito al disco");
      
      final savedSize = await tempImage.length();
      print("  📊 Tamaño del archivo guardado: $savedSize bytes");
      
      if (savedSize == 0) {
        print("  ❌ ERROR: Archivo guardado pero está vacío!");
        throw Exception("Archivo vacío");
      }

      print("  📊 Verificando integridad del archivo PNG...");
      final bytes = await tempImage.readAsBytes();
      print("  📊 Bytes leídos: ${bytes.length}");
      
      // Verificar header PNG
      if (bytes.length >= 8) {
        final header = bytes.sublist(0, 8);
        final isPNG = header[0] == 137 && header[1] == 80 && 
                     header[2] == 78 && header[3] == 71;
        print("  📊 Header PNG válido: ${isPNG ? '✅ SÍ' : '❌ NO'}");
      }

      // NUEVO: Aplicar preprocessing a la imagen
      print("  📊 Aplicando preprocessing a la imagen...");
      enhancedImage = await ImagePreprocessor.enhanceForOCR(tempImage);
      print("  ✅ Imagen mejorada para OCR");

      print("  📊 Enviando imagen (2400x3200 + preprocessing) a HybridAnalyzer...");
      final result = await _hybridAnalyzer.analyzeImage(enhancedImage, questionCount);
      print("  📊 HybridAnalyzer retornó: ${(result['answers'] as List?)?.length ?? 0} respuestas");

      await page.close();
      await document.close();
      print("  ✅ Recursos del PDF liberados");

      return result;
    } catch (e) {
      print("  ❌ Excepción en alta resolución: $e");
      print("  ❌ Stack: ${StackTrace.current}");
      return {'studentName': '', 'answers': []};
    } finally {
      // Limpiar imágenes temporales
      if (tempImage != null && tempImage.existsSync()) {
        try {
          await tempImage.delete();
          print("  🧹 Imagen temporal eliminada");
        } catch (e) {
          print("  ⚠️ No se pudo eliminar imagen temporal: $e");
        }
      }
      if (enhancedImage != null && enhancedImage.existsSync()) {
        try {
          await enhancedImage.delete();
          print("  🧹 Imagen mejorada eliminada");
        } catch (e) {
          print("  ⚠️ No se pudo eliminar imagen mejorada: $e");
        }
      }
    }
  }

  /// Estrategia 2: Conversión a imagen estándar
  Future<Map<String, dynamic>> _analyzeViaStandardImage(
    File pdfFile,
    int questionCount,
  ) async {
    File? tempImage;
    File? enhancedImage;
    try {
      print("  📊 Abriendo PDF...");
      final document = await PdfDocument.openFile(pdfFile.path);
      print("  ✅ PDF abierto exitosamente");
      print("  📊 Total de páginas: ${document.pagesCount}");
      
      final page = await document.getPage(1);
      print("  ✅ Página 1 obtenida correctamente");

      print("  📊 Renderizando a 1200x1600 (calidad estándar)...");
      final image = await page.render(width: 1200, height: 1600);

      if (image == null) {
        print("  ❌ ERROR: page.render() retornó NULL");
        throw Exception("Render retornó NULL");
      }

      print("  ✅ Renderizado completado");
      print("  📊 Dimensiones: ${image.width}x${image.height}");
      print("  📊 Bytes generados: ${image.bytes.length}");

      // Guardar temporalmente
      final tempDir = Directory.systemTemp;
      tempImage = File('${tempDir.path}/pdf_std_${DateTime.now().millisecondsSinceEpoch}.png');
      print("  📊 Guardando imagen temporal en: ${tempImage.path}");
      
      await tempImage.writeAsBytes(image.bytes);
      print("  ✅ Archivo escrito al disco");
      
      final savedSize = await tempImage.length();
      print("  📊 Tamaño del archivo guardado: $savedSize bytes");
      
      if (savedSize == 0) {
        print("  ❌ ERROR: Archivo guardado pero está vacío!");
        throw Exception("Archivo vacío");
      }

      print("  📊 Verificando integridad del archivo PNG...");
      final bytes = await tempImage.readAsBytes();
      print("  📊 Bytes leídos: ${bytes.length}");
      
      // Verificar header PNG
      if (bytes.length >= 8) {
        final header = bytes.sublist(0, 8);
        final isPNG = header[0] == 137 && header[1] == 80 && 
                     header[2] == 78 && header[3] == 71;
        print("  📊 Header PNG válido: ${isPNG ? '✅ SÍ' : '❌ NO'}");
      }

      // NUEVO: Aplicar preprocessing a la imagen
      print("  📊 Aplicando preprocessing a la imagen...");
      enhancedImage = await ImagePreprocessor.enhanceForOCR(tempImage);
      print("  ✅ Imagen mejorada para OCR");

      print("  📊 Enviando imagen (1200x1600 + preprocessing) a HybridAnalyzer...");
      final result = await _hybridAnalyzer.analyzeImage(enhancedImage, questionCount);
      print("  📊 HybridAnalyzer retornó: ${(result['answers'] as List?)?.length ?? 0} respuestas");

      await page.close();
      await document.close();
      print("  ✅ Recursos del PDF liberados");

      return result;
    } catch (e) {
      print("  ❌ Excepción en resolución estándar: $e");
      print("  ❌ Stack: ${StackTrace.current}");
      return {'studentName': '', 'answers': []};
    } finally {
      // Limpiar imágenes temporales
      if (tempImage != null && tempImage.existsSync()) {
        try {
          await tempImage.delete();
          print("  🧹 Imagen temporal eliminada");
        } catch (e) {
          print("  ⚠️ No se pudo eliminar imagen temporal: $e");
        }
      }
      if (enhancedImage != null && enhancedImage.existsSync()) {
        try {
          await enhancedImage.delete();
          print("  🧹 Imagen mejorada eliminada");
        } catch (e) {
          print("  ⚠️ No se pudo eliminar imagen mejorada: $e");
        }
      }
    }
  }

  Future<void> dispose() async {
    await textRecognizer.close();
  }
}
