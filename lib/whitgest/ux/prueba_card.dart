import 'package:flutter/material.dart';

/// Card de prueba con fondo blanco, icono y título grandes
/// 
/// Ejemplo:
/// ```dart
/// PruebaCard(
///   nombre: "Parcial 1",
///   docente: "Prof. Juan",
///   fecha: "2024-01-30",
///   onTap: () => Navigator.push(...),
/// )
/// ```
class PruebaCard extends StatelessWidget {
  final String nombre;
  final String docente;
  final String fecha;
  final VoidCallback onTap;

  const PruebaCard({
    super.key,
    required this.nombre,
    required this.docente,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono grande
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description,
                  size: 32,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 16),
              
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Prof: $docente - $fecha",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF95A5A6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flecha
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
