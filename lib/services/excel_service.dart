import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/student_record.dart';

class ExcelService {
  static Future<String> exportByCourse(List<StudentRecord> students) async {
    try {
      // Generate Excel file
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      // Group students by course
      final Map<String, List<StudentRecord>> grouped = {};
      for (final s in students) {
        grouped.putIfAbsent(s.course, () => []).add(s);
      }

      for (final entry in grouped.entries) {
        final courseName = entry.key;
        final courseStudents = entry.value
          ..sort((a, b) => b.totalMark.compareTo(a.totalMark));

        final sheetName = courseName.length > 28
            ? courseName.substring(0, 28)
            : courseName;
        final sheet = excel[sheetName];

        // Title row
        final titleCell = sheet.cell(CellIndex.indexByString('A1'));
        titleCell.value = TextCellValue('ICT University — $courseName Results');
        titleCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 13,
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: ExcelColor.fromHexString('#1A56DB'),
          horizontalAlign: HorizontalAlign.Center,
        );
        sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('I1'));

        // Date row
        final dateCell = sheet.cell(CellIndex.indexByString('A2'));
        dateCell.value = TextCellValue(
            'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
        dateCell.cellStyle = CellStyle(
          italic: true,
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('#555555'),
        );
        sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('I2'));

        // Headers
        final headers = [
          'Rank', 'Name', 'Matricule', 'Email',
          'CA1 (/20)', 'CA2 (/10)', 'Exam (/70)',
          'Total (/100)', 'GPA', 'Grade', 'Status'
        ];
        for (int col = 0; col < headers.length; col++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3));
          cell.value = TextCellValue(headers[col]);
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: 11,
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
            horizontalAlign: HorizontalAlign.Center,
          );
        }

        // Data rows
        for (int i = 0; i < courseStudents.length; i++) {
          final s = courseStudents[i];
          final rowIndex = i + 4;
          final isEven = i % 2 == 0;
          final bgColor = isEven ? '#F0F4FF' : '#FFFFFF';
          final statusColor = s.isPassing ? '#1A7A1A' : '#CC0000';
          final statusBg = s.isPassing ? '#E6F4E6' : '#FFE6E6';

          final rowData = [
            TextCellValue('${i + 1}'),
            TextCellValue(s.name),
            TextCellValue(s.matricule),
            TextCellValue(s.email),
            DoubleCellValue(s.ca1),
            DoubleCellValue(s.ca2),
            DoubleCellValue(s.exam),
            DoubleCellValue(double.parse(s.totalMark.toStringAsFixed(2))),
            DoubleCellValue(s.gpa),
            TextCellValue(s.letterGrade),
            TextCellValue(s.isPassing ? 'PASS' : 'FAIL'),
          ];

          for (int col = 0; col < rowData.length; col++) {
            final cell = sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
            cell.value = rowData[col];

            final isStatus = col == 10;
            cell.cellStyle = CellStyle(
              fontSize: 10,
              backgroundColorHex: ExcelColor.fromHexString(
                  isStatus ? statusBg : bgColor),
              fontColorHex: ExcelColor.fromHexString(
                  isStatus ? statusColor : '#1A1A1A'),
              bold: isStatus,
              horizontalAlign: col == 1 || col == 3
                  ? HorizontalAlign.Left
                  : HorizontalAlign.Center,
            );
          }
        }

        // Summary row
        final summaryRow = courseStudents.length + 5;
        final passingCount = courseStudents.where((s) => s.isPassing).length;
        final avgTotal = courseStudents.isEmpty
            ? 0.0
            : courseStudents.map((s) => s.totalMark).reduce((a, b) => a + b) /
                courseStudents.length;

        final summaryCell =
            sheet.cell(CellIndex.indexByString('A$summaryRow'));
        summaryCell.value = TextCellValue(
            'Total: ${courseStudents.length} students   |   '
            'Pass: $passingCount   |   '
            'Fail: ${courseStudents.length - passingCount}   |   '
            'Class Average: ${avgTotal.toStringAsFixed(2)}/100');
        summaryCell.cellStyle = CellStyle(
          bold: true,
          italic: true,
          fontSize: 10,
          backgroundColorHex: ExcelColor.fromHexString('#D0DCFF'),
          fontColorHex: ExcelColor.fromHexString('#1A3A6B'),
        );
        sheet.merge(
            CellIndex.indexByString('A$summaryRow'),
            CellIndex.indexByString('K$summaryRow'));

        // Set column widths
        final widths = [6.0, 22.0, 16.0, 32.0, 10.0, 10.0, 10.0, 12.0, 8.0, 8.0, 8.0];
        for (int i = 0; i < widths.length; i++) {
          sheet.setColumnWidth(i, widths[i]);
        }
      }

      // Encode Excel to bytes
      final List<int>? excelBytes = excel.encode();
      if (excelBytes == null) throw Exception('Failed to encode Excel file');

      final Uint8List bytes = Uint8List.fromList(excelBytes);

      // Option 1: Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Grade Report',
        fileName: 'ICT_Grades_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx',
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
      
      if (outputFile == null) {
        throw Exception('Save cancelled by user');
      }

      // Option 2: Try multiple ways to open the file
      bool opened = false;
      
      // Try 1: Use open_file package
      try {
        final result = await OpenFile.open(outputFile);
        if (result.type == ResultType.done) {
          opened = true;
          print('File opened successfully');
        } else {
          print('OpenFile failed: ${result.message}');
        }
      } catch (e) {
        print('OpenFile error: $e');
      }
      
      // Try 2: If open_file fails, show a dialog with file location
      if (!opened) {
        // Show a dialog telling user where the file is saved
        // This will be handled by the calling function
        print('File saved to: $outputFile');
      }
      
      return outputFile;
      
    } catch (e) {
      print('❌ Error exporting to Excel: $e');
      rethrow;
    }
  }
}