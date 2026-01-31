# Formato de Examen Esperado para Detección Óptima

## 📋 Estructura del Examen

```
Nombre: ________________

Pregunta 1
  ○ A) Primera opción
  ○ B) Segunda opción
  ○ C) Tercera opción
  ○ D) Cuarta opción

Pregunta 2
  ○ A) Primera opción
  ○ B) Segunda opción
  ○ C) Tercera opción
  ○ D) Cuarta opción

...más preguntas...
```

## 🎯 Cómo Marcar las Respuestas

El estudiante debe **PINTAR EL CÍRCULO** que está ANTES de la opción seleccionada:

### Ejemplo: Estudiante selecciona B en Pregunta 1

**ANTES (sin marcar):**
```
Pregunta 1
  ○ A) Primera opción
  ○ B) Segunda opción
  ○ C) Tercera opción
  ○ D) Cuarta opción
```

**DESPUÉS (marcado):**
```
Pregunta 1
  ○ A) Primera opción
  ● B) Segunda opción      ← Círculo PINTADO
  ○ C) Tercera opción
  ○ D) Cuarta opción
```

## 🔍 Lo Que el Sistema Busca

### ✅ CORRECTO (Detectado automáticamente):

1. **Círculo pintado Negro (●) ANTES de la letra:**
   ```
   ● A) opción
   ● B) opción
   ● C) opción
   ● D) opción
   ```

2. **Punto/bala (•) ANTES de la letra:**
   ```
   • A) opción
   • B) opción
   ```

3. **Círculo pequeño (o) relleno:**
   ```
   o A) opción
   o B) opción
   ```

4. **Otros símbolos rellenos:**
   ```
   ◉ A) opción
   ⬤ B) opción
   ⚫ C) opción
   ```

### ❌ NO DETECTADO (evitar):

1. **Círculo VACÍO (no pintado):**
   ```
   ○ A) opción  ← Esto NO cuenta
   ```

2. **Marca sin círculo:**
   ```
   ✓ A) opción  ← Prefer círculo
   X C) opción  ← Prefer círculo
   ```

3. **Símbolo DESPUÉS del literal:**
   ```
   A) ● opción  ← Mejor antes
   ```

4. **Solo letra pintada (sin círculo):**
   ```
   A) opción    ← Menos confiable
   ```

## 💡 Recomendaciones para Mejores Resultados

1. **Alineación uniforme:**
   - Todos los círculos deben estar alineados a la izquierda
   - Espaciado consistente entre líneas

2. **Claridad visual:**
   - Usar bolígrafo o marcador oscuro
   - Pintar completamente el círculo
   - Evitar manchas en otras opciones

3. **Formato consistente:**
   ```
   PREGUNTA N
   ○ A) Texto texto texto
   ○ B) Texto texto texto
   ○ C) Texto texto texto
   ○ D) Texto texto texto
   ```

4. **Fotografia de calidad:**
   - Buena iluminación (sin sombras)
   - Imagen centrada y derecha
   - Contraste claro entre círculos pintados y vacíos

## 📸 Ejemplo de Foto Óptima

```
[Foto clara, bien iluminada]

Nombre: Juan González Pérez

Pregunta 1
  ○ A) Madrid
  ● B) Barcelona          ← Visible claramente pintado
  ○ C) Valencia
  ○ D) Sevilla

Pregunta 2
  ● A) 25                 ← Círculo oscuro
  ○ B) 30
  ○ C) 35
  ○ D) 40
```

## 🔧 Sistema de Detección en Acción

El sistema hace esto automáticamente:

1. **Paso 1: Búsqueda de círculos pintados**
   - Busca símbolos rellenos: ● • ◉ ⚫ (antes del literal)
   - Identifica la opción marcada

2. **Paso 2: Validación**
   - Verifica que sea A, B, C o D
   - Verifica que sea número de pregunta válido
   - Descarta duplicados

3. **Paso 3: Lógica de exclusión (si no encuentra marca)**
   - Busca 3 círculos vacíos (○)
   - Identifica 1 círculo diferente (pintado)
   - Infiere esa como respuesta

4. **Paso 4: Refinamiento (si necesario)**
   - Para preguntas dudosas
   - Análisis microscópico de cada opción
   - Comparación de densidad visual

## 📊 Precisión Esperada

| Escenario | Precisión |
|-----------|-----------|
| Círculos bien pintados | 95%+ |
| Círculos algo tenues | 85-90% |
| Fotos ambiguas | 70-80% |
| Con refinamiento Gemini | +10-15% |

## 🎓 Caso de Uso Real

**Entrada:** Foto de examen escaneado
**Proceso:** Gemini Flash + ML Kit OCR
**Salida:**
```json
{
  "studentName": "Juan González Pérez",
  "answers": [
    {"q": 1, "val": "B"},
    {"q": 2, "val": "A"},
    {"q": 3, "val": "C"},
    ...
  ]
}
```

## 🚀 Próximos Pasos

1. Captura/Subida de imagen del examen
2. Sistema detecta automáticamente:
   - Nombre del estudiante
   - Respuestas marcadas (literal)
3. Compara con respuestas correctas
4. Calcula calificación

---

**Versión:** 2.0 (Optimizada para círculos)
**Última actualización:** 2026-01-28
**Estado:** ✅ Producción
