// lib/logic/calculator_engine.dart
class CalculatorEngine {
  String display = '0';

  double? _first;     // första operand
  String? _op;        // '+', '-', '*', '/'
  bool _shouldReset = false; // om nästa siffra ska börja om display

  // Visa heltal utan .0
  String _fmt(double v) =>
      (v == v.roundToDouble()) ? v.toInt().toString() : v.toString();

  // Nollställ allt (AC)
  void clearAll() {
    display = '0';
    _first = null;
    _op = null;
    _shouldReset = false;
  }

  // Hjälpare: mappa UI-symboler till interna operatorer
  String _normalizeOp(String v) {
    switch (v) {
      case '÷': return '/';
      case '×': return '*';
      case '−': return '-';
      default:  return v;
    }
  }

  // Backspace (korttryck på C)
  void _backspace() {
    if (_shouldReset || display == 'Error') {
      display = '0';
      _shouldReset = false;
      return;
    }
    if (display.length <= 1 || (display.length == 2 && display.startsWith('-'))) {
      display = '0';
    } else {
      display = display.substring(0, display.length - 1);
    }
  }

  void input(String v) {
    // --- siffror ---
    if ('0123456789'.contains(v)) {
      if (_shouldReset || display == '0' || display == 'Error') {
        display = v;
        _shouldReset = false;
      } else {
        display += v;
      }
      return;
    }

    // --- decimal (både . och , stöds) ---
    if (v == '.' || v == ',') {
      if (_shouldReset || display == 'Error') {
        display = '0';
        _shouldReset = false;
      }
      if (!display.contains('.')) display += '.';
      return;
    }

    // --- backspace på C (långtryck sköts i UI → clearAll()) ---
    if (v == 'C') {
      _backspace();
      return;
    }

    // --- ± (byt tecken) ---
    if (v == '±') {
      if (display != '0' && display != 'Error') {
        display = display.startsWith('-') ? display.substring(1) : '-$display';
      }
      return;
    }

    // --- procent (beräkna direkt, ingen '=' behövs) ---
    if (v == '%') {
      final current = double.tryParse(display);
      if (current == null) return;

      // Har vi ett uttryck? (X op Y%)
      if (_first != null && _op != null) {
        final op = _op!;
        double result;

        if (op == '+' || op == '-') {
          // Y% betyder "Y procent av X" för +/-
          final second = _first! * (current / 100.0);   // ex: 50 + 10% => 50 + (50*0.1)
          result = (op == '+') ? (_first! + second) : (_first! - second);
        } else {
          // För × och ÷: Y% betyder "Y/100"
          final second = current / 100.0;               // ex: 50 ÷ 10% => 50 ÷ 0.1
          if (op == '*') {
            result = _first! * second;
          } else {
            // op == '/'
            result = (second == 0) ? double.nan : _first! / second;
          }
        }

        display = result.isNaN ? 'Error' : _fmt(result);
        _first = null;
        _op = null;
        _shouldReset = true; // nästa knapptryck börjar nytt tal
        return;
      }

      // Fristående procent: 50 % → 0.5 (och redo för vidare räkning)
      display = _fmt(current / 100.0);
      _first = double.tryParse(display);
      _op = null;
      _shouldReset = true;
      return;
    }

    // --- operatorer ---
    if ('+-−×*/÷'.contains(v)) {
      final op = _normalizeOp(v);
      // Kedjeberäkning: om det redan finns ett uttryck och displayen är ett tal → räkna först
      final current = double.tryParse(display);
      if (_first != null && _op != null && current != null && !_shouldReset) {
        // utför tidigare operation
        switch (_op!) {
          case '+': display = _fmt(_first! + current); break;
          case '-': display = _fmt(_first! - current); break;
          case '*': display = _fmt(_first! * current); break;
          case '/': display = (current == 0) ? 'Error' : _fmt(_first! / current); break;
        }
      }
      // sätt nytt "första tal" och operator
      _first = double.tryParse(display);
      _op = op;
      _shouldReset = true;
      return;
    }

    // --- lika med ---
    if (v == '=') {
      final current = double.tryParse(display);
      if (_first != null && _op != null && current != null) {
        switch (_op!) {
          case '+': display = _fmt(_first! + current); break;
          case '-': display = _fmt(_first! - current); break;
          case '*': display = _fmt(_first! * current); break;
          case '/': display = (current == 0) ? 'Error' : _fmt(_first! / current); break;
        }
        _first = null;
        _op = null;
        _shouldReset = true;
      }
      return;
    }

    // --- AC (om du skickar 'AC' direkt) ---
    if (v == 'AC') {
      clearAll();
      return;
    }
  }
}