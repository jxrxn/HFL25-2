import 'dart:convert';
import 'dart:io';

void main() async {
  const path = 'test/mock_heroes.json';
  final f = File(path);
  if (!f.existsSync()) {
    stderr.writeln('Hittar inte $path');
    exitCode = 1;
    return;
  }

  final raw = await f.readAsString();
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

  // Filtrera bort din extra hjälte (id eller name)
  final cleaned = list.where((e) =>
    e['id'] != '2fdd83a2-7b73-4a4f-90ca-59bbeddaf316' &&
    (e['name'] as String?)?.toLowerCase() != 'm'
  ).toList();

  await f.writeAsString(const JsonEncoder.withIndent('  ').convert(cleaned));
  print('Cleaned ${list.length - cleaned.length} entr(y/ies). Now: ${cleaned.length}.');
}
