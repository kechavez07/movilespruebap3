# MANUAL DE INSTALACIÓN Y USO

**Universidad de las Fuerzas Armadas - ESPE**

**Materia:** Desarrollo de Aplicaciones Móviles

**Nombre:** Kleber Chavez

**Tema:** Prueba Tercer Parcial

---

## 📋 Tabla de Contenidos
1. [Descripción General](#descripción-general)
2. [Requerimientos Técnicos](#requerimientos-técnicos)
3. [Instalación del APK](#instalación-del-apk)
4. [Funcionalidades Principales](#funcionalidades-principales)
5. [Guía de Uso](#guía-de-uso)
6. [Requisitos del Sistema](#requisitos-del-sistema)

---

## 📱 Descripción General

**"Evaluador Tests Inteligente"** es una aplicación móvil desarrollada en Flutter que permite:

- Crear y gestionar pruebas/evaluaciones
- Escanear preguntas desde PDF usando OCR (Reconocimiento de Caracteres)
- Calificar automáticamente las respuestas
- Generar reportes en Excel y PDF
- Almacenar datos localmente en base de datos SQLite

La aplicación utiliza **Google ML Kit** para OCR (sin necesidad de API key) y es completamente funcional de forma offline una vez instalada.

---

## 🔧 Requerimientos Técnicos

### Para Instalar el APK:

| Requisito | Versión Mínima | Descripción |
|-----------|----------------|-------------|
| **Android** | 5.0 (API 21) | Sistema operativo mínimo requerido |
| **RAM** | 2 GB | Memoria recomendada para ejecutar sin problemas |
| **Almacenamiento** | 100 MB | Espacio libre para la aplicación |
| **Pantalla** | 4.5"+ | Tamaño mínimo recomendado |
| **Permisos** | - | Cámara, Almacenamiento, Galería |

### Dependencias de la Aplicación (Incluidas en APK):

```
✅ Google ML Kit Text Recognition v0.13.0  → OCR offline
✅ SQLite v2.3.3                           → Base de datos local
✅ File Picker v8.0.3                      → Seleccionar archivos
✅ Image Picker v1.1.1                     → Acceso a galería
✅ PDF Rendering v2.4.0                    → Lectura de PDF
✅ Excel Export v4.0.3                     → Generación de reportes
✅ PDF Generation v5.13.2                  → Exportar a PDF
✅ Provider v6.1.2                         → Gestión de estado
```

---

## 📲 Instalación del APK

### Paso 1: Descargar el APK
- Obtén el archivo **`prueba_parcial_p3.apk`** generado con `flutter run`

### Paso 2: Habilitar Instalación de Fuentes Desconocidas (Android)

1. **Abre Configuración** del dispositivo
2. Ve a **Seguridad** (o **Privacidad** en algunos modelos)
3. Busca la opción **"Fuentes desconocidas"** o **"Instalar aplicaciones desconocidas"**
4. **Habilita** la opción para tu navegador o aplicación de archivos
   - Android 8.0+: Permite instalar desde una aplicación específica
   - Android 5.0-7.0: Opción general en Seguridad

### Paso 3: Instalar el APK

**Opción A: Mediante Gestor de Archivos**
1. Abre el **Gestor de Archivos**
2. Navega a la carpeta donde guardaste el APK
3. Haz clic en **`prueba_parcial_p3.apk`**
4. Selecciona **"Instalar"**
5. Espera a que se complete la instalación
6. Abre la aplicación

**Opción B: Mediante USB y Android Debug Bridge (ADB)**
```bash
adb install prueba_parcial_p3.apk
```

### Paso 4: Otorgar Permisos
Al abrir la aplicación por primera vez, concede los siguientes permisos:
- ✅ **Cámara** → Para escanear código QR o tomar fotos
- ✅ **Almacenamiento** → Para acceder a archivos PDF
- ✅ **Galería** → Para seleccionar imágenes y documentos

---

## 🎯 Funcionalidades Principales

### 1. **Gestión de Materias**
   - Crear nuevas materias/cursos
   - Listar todas las materias registradas
   - Eliminar materias (y sus pruebas asociadas)

### 2. **Creación de Pruebas**
   - Crear nuevas pruebas vinculadas a una materia
   - Definir número de preguntas
   - Establecer fecha y hora
   - Asignar puntuación

### 3. **Lectura de Preguntas (OCR)**
   - Escanear preguntas desde PDF
   - Captura automática mediante cámara
   - Reconocimiento inteligente de texto offline
   - Edición manual de preguntas capturadas

### 4. **Calificación Automática**
   - Evaluar respuestas automáticamente
   - Comparación inteligente de respuestas
   - Registro de puntajes

### 5. **Generación de Reportes**
   - Exportar resultados a **Excel** (`.xlsx`)
   - Generar reportes en **PDF** (`.pdf`)
   - Incluir gráficos y estadísticas

### 6. **Almacenamiento Local**
   - Base de datos SQLite integrada
   - Toda la información se guarda en el dispositivo
   - **No requiere conexión a internet**

---

## 📖 Guía de Uso

### Flujo Principal de la Aplicación

#### **1. Inicio - Pantalla Principal**
```
Inicio
   ├─ Botón: "Gestionar Materias" → Ir a Materias
   ├─ Botón: "Crear Prueba" → Ir a Pruebas
   └─ Botón: "Ver Resultados" → Ir a Resultados
```

#### **2. Gestión de Materias**
```
Materias
   ├─ [+] Botón Agregar Nueva Materia
   │   └─ Ingresa nombre de la materia
   ├─ Listar materias existentes
   └─ Eliminar materia (desliza o toca opciones)
```

#### **3. Crear una Prueba**
```
Pruebas
   ├─ [+] Nueva Prueba
   │   ├─ Selecciona materia
   │   ├─ Ingresa nombre de prueba
   │   ├─ Define número de preguntas
   │   ├─ Establece fecha/hora
   │   └─ Guarda
   └─ Ver pruebas creadas
```

#### **4. Agregar Preguntas (OCR)**
```
Detalles de Prueba
   ├─ [+] Agregar Pregunta
   │   ├─ Opción A: Escribir manualmente
   │   ├─ Opción B: Escanear desde PDF
   │   │   └─ Selecciona archivo PDF
   │   │       └─ App extrae texto automáticamente
   │   └─ Confirmar pregunta
   └─ Ver lista de preguntas
```

#### **5. Calificar Pruebas**
```
Evaluación
   ├─ Selecciona prueba
   ├─ Por cada pregunta:
   │   ├─ Ver respuesta del estudiante
   │   ├─ Ver respuesta correcta
   │   └─ Asignar puntuación automática/manual
   └─ Guardar calificaciones
```

#### **6. Generar Reportes**
```
Resultados
   ├─ Selecciona prueba
   ├─ Opciones de exportación:
   │   ├─ Exportar a Excel (con gráficos)
   │   └─ Exportar a PDF (formateado)
   └─ Los archivos se guardan en descargas
```

---

## 💻 Requisitos del Sistema

### Dispositivo Android

#### **Mínimos (Funcionamiento Básico)**
- Android 5.0 (API 21)
- 2 GB RAM
- 100 MB almacenamiento libre
- Pantalla 4.5"

#### **Recomendados (Experiencia Óptima)**
- Android 8.0+ (API 28 o superior)
- 4 GB RAM
- 200 MB almacenamiento libre
- Pantalla 5.0"+
- Procesador quad-core o superior

#### **Características Necesarias**
- ✅ Cámara (para escanear PDF)
- ✅ Almacenamiento externo (para guardar reportes)
- ✅ Sensor de luz (opcional, para mejor escaneo)

---

## ⚙️ Configuración Inicial

### Primera Ejecución

1. **Instala la aplicación** (ver sección anterior)
2. **Abre "Evaluador Tests Inteligente"**
3. **Concede los permisos solicitados:**
   - Cámara
   - Almacenamiento
   - Galería
4. **La aplicación está lista para usar**

### Notas Importantes

- ❌ **No requiere API key de Google** (ML Kit incluido)
- ❌ **No requiere conexión a internet** (función offline)
- ✅ Los datos se guardan localmente en el dispositivo
- ✅ Los reportes se guardan en `Descargas/` del dispositivo

---

## 🚀 Características Técnicas Avanzadas

### Base de Datos (SQLite)
- Tablas: Materias, Pruebas, Preguntas, Resultados
- Almacenamiento: `/data/data/com.example.prueba_parcial_p3/databases/`
- Totalmente integrada (sin instalación externa)

### OCR (Reconocimiento de Caracteres)
- Motor: Google ML Kit (offline)
- Soporta: Español, Inglés, y múltiples idiomas
- Precisión: ~95% en documentos claros

### Gestión de Estado
- Provider v6.1.2 para estado reactivo
- Multi-provider para modelos complejos
- Notificadores para actualizaciones en tiempo real

---

## 📞 Troubleshooting (Solución de Problemas)

### Problema: "No se puede instalar el APK"
**Solución:**
1. Verifica que hayas habilitado "Fuentes desconocidas"
2. Asegúrate de tener 100 MB libres
3. Descarga nuevamente el APK

### Problema: "App se cierra al iniciar"
**Solución:**
1. Reinicia el dispositivo
2. Desinstala y reinstala la app
3. Verifica que tengas Android 5.0+

### Problema: "No escanea los PDF correctamente"
**Solución:**
1. Asegúrate que el PDF sea legible (texto, no imagen)
2. Mejora la iluminación si usas cámara
3. Edita manualmente si es necesario

### Problema: "No puedo exportar a Excel/PDF"
**Solución:**
1. Verifica espacio de almacenamiento disponible
2. Concede permisos de escritura en almacenamiento
3. Los archivos estarán en `Descargas/`

---

## 📊 Estructura de Datos Exportados

### Excel (.xlsx)
```
Hoja 1: Resultados
├─ Columnas: ID, Materia, Prueba, Estudiante, Calificación, Fecha
└─ Incluye gráficos y estadísticas

Hoja 2: Detalle Preguntas
└─ Respuestas y calificación por pregunta
```

### PDF (.pdf)
```
- Encabezado: Datos de la prueba
- Cuerpo: Preguntas y respuestas
- Pie: Estadísticas y firma
```

---

## ✨ Versión de la Aplicación

- **Nombre:** Evaluador Tests Inteligente
- **Versión:** 1.0.0
- **Build:** 1
- **Desarrollador:** Kleber Chavez
- **Materia:** Desarrollo de Aplicaciones Móviles
- **Institución:** Universidad de las Fuerzas Armadas - ESPE

---

## 📄 Licencia y Términos

Esta aplicación es un proyecto académico desarrollado como prueba del tercer parcial de la materia Desarrollo de Aplicaciones Móviles en ESPE.

---

## 🔗 Recursos Útiles

- [Documentación Flutter](https://flutter.dev/)
- [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition)
- [SQLite en Flutter](https://pub.dev/packages/sqflite)
- [Provider State Management](https://pub.dev/packages/provider)

---

**Última actualización:** 2026-02-01

**Para soporte o preguntas:** contactar a Kleber Chavez
