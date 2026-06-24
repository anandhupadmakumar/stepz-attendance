import 'dart:io';

void saveExcelFile(List<int> bytes, String filename) {
  final file = File(filename);
  file.writeAsBytesSync(bytes);
}
