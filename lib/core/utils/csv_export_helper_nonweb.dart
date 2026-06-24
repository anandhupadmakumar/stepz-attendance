import 'dart:io';

void saveCsvFile(String csvContent, String filename) {
  final file = File(filename);
  file.writeAsStringSync(csvContent);
}
