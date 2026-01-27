
import 'package:flutter/material.dart';

class InstallationPage extends StatelessWidget {
  const InstallationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manual de Instalación")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Requerimientos Técnicos",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSection("Hardware", 
              "- Dispositivo Android 8.0 o superior.\n"
              "- Cámara trasera funcional (Min 12MP recomendado).\n"
              "- Conexión a Internet (Wifi/Datos) para la IA."
            ),
            _buildSection("Permisos", 
              "- Cámara: Para escanear las pruebas.\n"
              "- Almacenamiento: Para guardar PDF y Excel."
            ),
            _buildSection("Configuración IA", 
              "- Se requiere una API KEY de Google Gemini.\n"
              "- Configure la llave en el archivo lib/AI/gemini_config.dart antes de compilar."
            ),
             _buildSection("Instalación", 
              "1. Instale el APK generado.\n"
              "2. Acepte los permisos de cámara y archivos.\n"
              "3. Asegúrese de tener conexión a Internet."
            ),
             _buildSection("Uso Básico", 
              "1. Cree una Materia en 'Gestionar Materias'.\n"
              "2. Cree una Prueba dentro de la materia.\n"
              "3. Agregue preguntas (o importe archivo Aiken).\n"
              "4. Genere el PDF e imprímalo.\n"
              "5. Tome la prueba a los estudiantes.\n"
              "6. Use 'Escanear Prueba' en la pestaña Resultados para calificar automáticamente."
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 5),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
