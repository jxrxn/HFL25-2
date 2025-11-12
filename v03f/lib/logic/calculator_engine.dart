/// Pure calculation state & logic (no widgets)
class CalculatorEngine {
  String display = '0';
  double? _first;
  String? _op;
  bool _shouldReset = false;

  // format 49.0 -> "49"
  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void input(String value) {
    if ('0123456789'.contains(value)) {
      if (_shouldReset || display == '0') {
        display = value;
        _shouldReset = false;
      } else {
        display += value;
      }
      return;
    }

    if ('+-*/'.contains(value)) {
      _first = double.tryParse(display);
      _op = value;
      _shouldReset = true;
      return;
    }

    if (value == '=') {
      final second = double.tryParse(display);
      if (_first != null && _op != null && second != null) {
        switch (_op) {
          case '+':
            display = _fmt(_first! + second);
            break;
          case '-':
            display = _fmt(_first! - second);
            break;
          case '*':
            display = _fmt(_first! * second);
            break;
          case '/':
            display = second == 0 ? 'Error' : _fmt(_first! / second);
            break;
        }
        _first = null;
        _op = null;
        _shouldReset = true;
      }
      return;
    }

    if (value == 'C') {
      display = '0';
      _first = null;
      _op = null;
      _shouldReset = false;
    }
  }
}