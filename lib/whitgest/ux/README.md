# Componentes Reutilizables UX

Esta carpeta contiene todos los widgets reutilizables de la aplicación, organizados por categoría.

## 📦 Importación

Para usar todos los componentes, importa el archivo principal:

```dart
import 'package:prueba_parcial_p3/whitgest/ux/ux_components.dart';
```

O importa componentes específicos:

```dart
import 'package:prueba_parcial_p3/whitgest/ux/custom_button.dart';
import 'package:prueba_parcial_p3/whitgest/ux/custom_input.dart';
```

## 🎨 Componentes Disponibles

### Botones (`custom_button.dart`)
- **PrimaryButton**: Botón principal con icono opcional
- **SecondaryButton**: Botón secundario con borde
- **IconButton**: Botón circular de icono
- **CustomFAB**: Botón flotante de acción

### Inputs (`custom_input.dart`)
- **CustomInput**: Campo de texto con validación
- **SearchInput**: Campo de búsqueda
- **ScoreInput**: Campo numérico para puntuaciones
- **DateInput**: Selector de fecha

### Tarjetas (`custom_card.dart`)
- **CustomCard**: Tarjeta base personalizable
- **StudentCard**: Tarjeta para estudiantes
- **SubjectCard**: Tarjeta para materias
- **ResultCard**: Tarjeta para resultados de pruebas

### Títulos (`custom_title.dart`)
- **PageTitle**: Título de página
- **SectionTitle**: Título de sección
- **SubtitleText**: Texto descriptivo
- **ListHeader**: Encabezado de lista con contador
- **InfoBadge**: Etiqueta informativa

### Notificaciones (`notification_widget.dart`)
- **showNotification()**: Función para mostrar SnackBar
- **NotificationBanner**: Banner persistente
- **ToastNotification**: Toast ligero

### Indicadores de Carga (`loading_indicator.dart`)
- **LoadingIndicator**: Indicador circular
- **LoadingOverlay**: Overlay de carga
- **ProgressIndicator**: Barra de progreso
- **SkeletonLoader**: Skeleton para listas
- **EmptyState**: Estado vacío

### Diálogos (`custom_dialog.dart`)
- **showConfirmDialog()**: Diálogo de confirmación
- **showInfoDialog()**: Diálogo informativo
- **showInputDialog()**: Diálogo con input
- **showSelectionDialog()**: Diálogo de selección
- **showCustomBottomSheet()**: Bottom sheet modal
- **LoadingDialog**: Diálogo de carga

## 💡 Ejemplos de Uso

### Botón Primario
```dart
PrimaryButton(
  text: 'Guardar',
  icon: Icons.save,
  onPressed: () => print('Guardado'),
  isLoading: false,
)
```

### Campo de Texto
```dart
CustomInput(
  label: 'Nombre del estudiante',
  controller: _nameController,
  icon: Icons.person,
  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
)
```

### Tarjeta de Estudiante
```dart
StudentCard(
  name: 'Juan Pérez',
  studentId: '2024001',
  email: 'juan@example.com',
  onEdit: () => print('Editar'),
  onDelete: () => print('Eliminar'),
)
```

### Notificación
```dart
showNotification(
  context,
  'Estudiante guardado correctamente',
  type: NotificationType.success,
);
```

### Diálogo de Confirmación
```dart
final confirmed = await showConfirmDialog(
  context,
  title: 'Eliminar estudiante',
  message: '¿Está seguro?',
  isDangerous: true,
);
if (confirmed) {
  // Realizar acción
}
```

## 🎯 Convenciones

- Todos los componentes están completamente comentados en español
- Cada widget incluye ejemplos de uso en los comentarios
- Los colores se adaptan automáticamente al tema de la aplicación
- Todos los widgets son responsivos y siguen Material Design
