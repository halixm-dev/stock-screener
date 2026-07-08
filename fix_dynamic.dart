// Actually, simple regex is enough.
import 'dart:io';

void main() {
  final file = File('lib/domain/signal_engine.dart');
  var content = file.readAsStringSync();

  // A dirty but effective regex for these specific methods.
  // The parameters are on lines by themselves like "    rf," or "    rqk," etc.
  // We'll just replace `    ([a-z0-9A-Z]+),` with `    dynamic $1,`
  // But only inside the parameter lists of those 4 methods.

  // It's safer to just replace any line with exactly 4 spaces, a word, and a comma.
  content = content.replaceAllMapped(
    RegExp(r'^    ([a-z0-9A-Z]+),$', multiLine: true),
    (match) {
      final name = match.group(1)!;
      return '    dynamic $name,';
    },
  );

  // Also fix lines with 8 spaces for the function calls inside those methods
  // wait, function calls inside should NOT be changed to `dynamic arg,`.
  // Wait, the regex `^    ([a-z0-9A-Z]+),$`, `^` matches beginning of line. Inside the file, function arguments in calls (like `if (!_getLeadingLong( ... rf, ...))`) might be indented with 8 spaces. The regex only matches 4 spaces. Let's verify indentation.
  file.writeAsStringSync(content);
}
