
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../logica/providers/app_provider.dart';
import '../whitgest/ux/gradient_option_card.dart';
import '../whitgest/ux/widgets.dart';
import 'materias_page.dart';
import 'installation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() => 
      Provider.of<AppProvider>(context, listen: false).loadMaterias()
    );
  }

  Future<void> _generarArchivoAiken() async {
    try {
      // Contenido del archivo con preguntas de ejemplo
      final contenido = '''¿Cuál es la capital de Francia?
A) Londres
B) Berlín
C) París
D) Madrid
ANSWER: C

¿Cuál es el planeta más grande del sistema solar?
A) Tierra
B) Saturno
C) Júpiter
D) Neptuno
ANSWER: C

¿Quién escribió "Don Quijote"?
A) Jorge Luis Borges
B) Miguel de Cervantes
C) Federico García Lorca
D) Pablo Neruda
ANSWER: B

¿En qué año comenzó la Primera Guerra Mundial?
A) 1912
B) 1914
C) 1916
D) 1918
ANSWER: B

¿Cuál es el elemento químico con símbolo Au?
A) Plata
B) Aluminio
C) Oro
D) Cobre
ANSWER: C

¿Cuál es la montaña más alta del mundo?
A) K2
B) Kangchenjunga
C) Everest
D) Lhotse
ANSWER: C

¿Cuántos lados tiene un octágono?
A) 6
B) 7
C) 8
D) 9
ANSWER: C

¿Cuál es la velocidad de la luz?
A) 300,000 km/s
B) 150,000 km/s
C) 450,000 km/s
D) 600,000 km/s
ANSWER: A

¿Quién fue el primer presidente de los EE.UU.?
A) Thomas Jefferson
B) Abraham Lincoln
C) George Washington
D) John Adams
ANSWER: C

¿Cuál es el idioma más hablado en el mundo?
A) Español
B) Inglés
C) Chino Mandarín
D) Árabe
ANSWER: C''';

      // Obtener el directorio de descargas
      final directory = await getDownloadsDirectory();
      final filePath = '${directory?.path}/ejemplo_preguntas_aiken.txt';
      
      // Crear y guardar el archivo
      final file = File(filePath);
      await file.writeAsString(contenido);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Archivo generado correctamente'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.purple.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Evaluador Inteligente",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Analiza y califica PDFs automáticamente",
                        style: TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Opciones
                GradientOptionCard(
                  icon: Icons.class_,
                  title: "Gestionar Materias",
                  subtitle: "Crea materias, pruebas\ny estudiantes.",
                  gradient: [Colors.blue.shade300, Colors.cyan.shade300],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MateriasPage()));
                  },
                ),
                
                const SizedBox(height: 16),
                
                GradientOptionCard(
                  icon: Icons.help_outline,
                  title: "Manual de Instalación",
                  subtitle: "Requerimientos y\nconfiguraciones.",
                  gradient: [Colors.purple.shade300, Colors.indigo.shade300],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallationPage()));
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Tarjeta Formato Aiken
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Encabezado con gradiente
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: kPrimaryGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color:  kPrimaryColor, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Formato de ejemplo de Aiken",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:  kPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Contenido
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Descripción:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Formato de como deben ser las preguntas si las quieres importar desde un archivo de texto.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  "¿Cuál es la capital de Francia?\n"
                                  "A) Londres\n"
                                  "B) Berlín\n"
                                  "C) París\n"
                                  "D) Madrid\n"
                                  "ANSWER: C\n"
                                  "\n"
                                  "¿Cuál es el planeta más grande?\n"
                                  "A) Tierra\n"
                                  "B) Júpiter\n"
                                  "C) Saturno\n"
                                  "D) Neptuno\n"
                                  "ANSWER: B",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Courier',
                                    color: Colors.black87,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Text(
                                "📌 Reglas:\n"
                                "• Cada pregunta debe ir en una línea\n"
                                "• Las opciones van como A), B), C), D)\n"
                                "• Separa preguntas con una línea vacía\n"
                                "• La respuesta correcta va en: ANSWER: [A/B/C/D]\n"
                                "• Solo soporta preguntas de opción múltiple",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _generarArchivoAiken,
                                icon: const Icon(Icons.download, size: 20),
                                label: const Text(
                                  "Descargar archivo de ejemplo",
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
