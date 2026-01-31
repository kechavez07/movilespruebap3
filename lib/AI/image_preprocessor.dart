import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 🖼️ Preprocesamiento de imágenes para mejorar OCR
/// Aplica filtros para aumentar contraste y claridad
class ImagePreprocessor {
  
  /// Mejora la imagen para OCR usando contraste y brillo
  static Future<File> enhanceForOCR(File imageFile) async {
    print("🖼️  [ImagePreprocessor] Iniciando mejora de imagen...");
    print("🖼️  [ImagePreprocessor] Archivo original: ${imageFile.path}");
    print("🖼️  [ImagePreprocessor] Tamaño: ${await imageFile.length()} bytes");
    
    try {
      // 1. Leer imagen
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        print("❌ [ImagePreprocessor] No se pudo decodificar la imagen");
        return imageFile; // Retornar original si falla
      }
      
      print("🖼️  [ImagePreprocessor] Imagen decodificada: ${originalImage.width}x${originalImage.height}");
      
      // 2. Aplicar mejoras
      var processedImage = _enhanceContrast(originalImage);
      print("🖼️  [ImagePreprocessor] ✅ Contraste mejorado");
      
      processedImage = _adjustBrightness(processedImage);
      print("🖼️  [ImagePreprocessor] ✅ Brillo ajustado");
      
      // 3. Guardar imagen mejorada
      final enhancedBytes = img.encodePng(processedImage);
      print("🖼️  [ImagePreprocessor] Imagen procesada: ${enhancedBytes.length} bytes");
      
      // Guardar en archivo temporal
      final tempDir = Directory.systemTemp;
      final enhancedFile = File('${tempDir.path}/ocr_enhanced_${DateTime.now().millisecondsSinceEpoch}.png');
      await enhancedFile.writeAsBytes(enhancedBytes);
      print("🖼️  [ImagePreprocessor] ✅ Imagen mejorada guardada: ${enhancedFile.path}");
      
      return enhancedFile;
    } catch (e) {
      print("❌ [ImagePreprocessor] Error durante preprocessing: $e");
      return imageFile; // Retornar original en caso de error
    }
  }
  
  /// Mejora el contraste de la imagen usando stretching de histograma
  static img.Image _enhanceContrast(img.Image image) {
    print("  📊 Mejorando contraste...");
    
    // Encontrar min y max valores
    int minVal = 255, maxVal = 0;
    
    for (final pixel in image) {
      final gray = _pixelToGray(pixel);
      if (gray < minVal) minVal = gray;
      if (gray > maxVal) maxVal = gray;
    }
    
    print("  📊 Rango de píxeles: $minVal - $maxVal");
    
    // Stretch contraste
    final range = maxVal - minVal;
    if (range <= 0) return image;
    
    final enhanced = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final gray = _pixelToGray(pixel);
        final normalized = ((gray - minVal) * 255 ~/ range).clamp(0, 255);
        enhanced.setPixelRgba(x, y, normalized, normalized, normalized, 255);
      }
    }
    
    return enhanced;
  }
  
  /// Ajusta el brillo
  static img.Image _adjustBrightness(img.Image image) {
    print("  📊 Ajustando brillo...");
    
    const brightnessFactor = 1.1; // Aumentar 10% brillo
    
    final adjusted = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final gray = _pixelToGray(pixel);
        final brightened = (gray * brightnessFactor).toInt().clamp(0, 255);
        adjusted.setPixelRgba(x, y, brightened, brightened, brightened, 255);
      }
    }
    
    return adjusted;
  }
  
  /// Convierte un píxel a escala de grises
  static int _pixelToGray(img.Pixel pixel) {
    // Fórmula estándar: 0.299*R + 0.587*G + 0.114*B
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    return ((0.299 * r + 0.587 * g + 0.114 * b).toInt());
  }
}

