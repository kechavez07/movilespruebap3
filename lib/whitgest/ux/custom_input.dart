import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto personalizado con validación y estilos consistentes
/// 
/// Este widget proporciona un TextField con diseño uniforme para toda la aplicación
/// 
/// Ejemplo de uso:
/// ```dart
/// CustomInput(
///   label: 'Nombre del estudiante',
///   controller: _nameController,
///   icon: Icons.person,
///   validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
/// )
/// ```
class CustomInput extends StatelessWidget {
  /// Etiqueta del campo
  final String label;
  
  /// Controlador del texto
  final TextEditingController controller;
  
  /// Indica si es un campo de contraseña
  final bool isPassword;
  
  /// Número máximo de líneas
  final int maxLines;
  
  /// Tipo de teclado
  final TextInputType keyboardType;
  
  /// Icono opcional al inicio del campo
  final IconData? icon;
  
  /// Texto de ayuda debajo del campo
  final String? helperText;
  
  /// Función de validación
  final String? Function(String?)? validator;
  
  /// Indica si el campo es de solo lectura
  final bool readOnly;
  
  /// Función que se ejecuta al tocar el campo (útil para pickers)
  final VoidCallback? onTap;
  
  /// Texto de sugerencia (placeholder)
  final String? hintText;
  
  /// Formateadores de entrada
  final List<TextInputFormatter>? inputFormatters;
  
  /// Indica si el campo está habilitado
  final bool enabled;

  const CustomInput({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.helperText,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.hintText,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      enabled: enabled,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

/// Campo de búsqueda con icono de lupa
class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchInput({
    super.key,
    required this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Campo numérico para puntuación
class ScoreInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double? maxValue;
  final double? minValue;

  const ScoreInput({
    super.key,
    required this.label,
    required this.controller,
    this.maxValue,
    this.minValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomInput(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      icon: Icons.grade,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo requerido';
        }
        final number = double.tryParse(value);
        if (number == null) {
          return 'Ingrese un número válido';
        }
        if (minValue != null && number < minValue!) {
          return 'Mínimo: $minValue';
        }
        if (maxValue != null && number > maxValue!) {
          return 'Máximo: $maxValue';
        }
        return null;
      },
    );
  }
}

/// Selector de fecha
class DateInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateInput({
    super.key,
    required this.label,
    required this.controller,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return CustomInput(
      label: label,
      controller: controller,
      icon: Icons.calendar_today,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (date != null) {
          controller.text = '${date.day}/${date.month}/${date.year}';
        }
      },
    );
  }
}
