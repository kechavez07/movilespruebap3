
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_models.dart';

class ExcelService {
  static Future<String> exportResultados(
      Prueba prueba, Materia materia, List<Estudiante> estudiantes, List<Resultado> resultados) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Resultados'];
    
    // Initial cleanup of default sheet
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Headers information
    sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue("Materia: ${materia.nombre}");
    sheetObject.cell(CellIndex.indexByString("A2")).value = TextCellValue("Docente: ${prueba.nombreDocente}");
    sheetObject.cell(CellIndex.indexByString("A3")).value = TextCellValue("Prueba: ${prueba.nombre}");
    sheetObject.cell(CellIndex.indexByString("A4")).value = TextCellValue("Fecha: ${prueba.fechaCreacion.toString().split(' ')[0]}");

    // Table Headers
    int startRow = 6;
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow)).value = TextCellValue("Nombre Estudiante");
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow)).value = TextCellValue("Identificación");
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow)).value = TextCellValue("Nota");
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: startRow)).value = TextCellValue("Fecha Realización");

    // Data
    for (int i = 0; i < resultados.length; i++) {
        Resultado res = resultados[i];
        Estudiante? est;
        try {
            est = estudiantes.firstWhere((e) => e.id == res.estudianteId);
        } catch (e) {
            // Student might have been deleted
        }

        var row = startRow + 1 + i;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(est?.nombre ?? "Desconocido");
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(est?.identificacion ?? "N/A");
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(res.calificacion);
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(res.fechaRealizacion.toString().split(' ')[0]);
    }

    // Save
    var fileBytes = excel.save();
    Directory? directory = await getApplicationDocumentsDirectory();
    
    // Sanitize filename
    String safeName = prueba.nombre.replaceAll(RegExp(r'[^\w\s]+'), '');
    String path = "${directory.path}/Resultados_$safeName.xlsx";
    
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);
      
    return path;
  }
}
