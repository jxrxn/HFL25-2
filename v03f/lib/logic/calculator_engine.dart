// lib/logic/calculator_engine.dart

class CalculatorEngine {
  // ===== Gränser för säkra tal =====
  static const int _maxSafeInt = 999999999999999; // 15 nior
  static const int _maxIntDigits = 15;
  static const int _maxTotalDigits = 20; // inkl decimaldel

  // ===== Intern state =====
  final List<_Tok> _tokens = <_Tok>[]; // infix: Num, Op, Num, Op, ...
  String _cur = '0';                   // pågående tal som text
  String? _error;
  bool _justEvaluated = false;

  // Om senaste inmatningen var '%' vill vi visa t.ex. "10 %"
  // i remsan (inte 0.1). Vi sparar då texten här.
  String? _curAsPercentText;

  // Senaste färdiga uttrycket, t.ex. "20 + 3 × 2 = 26"
  String? _lastStrip;

  // ===== Publika läsvärden =====

  /// Det som visas i stora displayen (live-resultat).
  String get display {
    if (_error != null) return 'Error';

    final preview = _evalPreview();
    if (preview != null) return _fmt(preview);

    // fallback: visa current
    final d = _toDouble(_cur);
    return _fmt(d ?? 0);
  }

  /// Den lilla remsan med uttrycket.
  String get strip => _buildStrip();

  // ===== Publika kommandon =====

  /// Långt tryck på C i UI kallar denna → full återställning.
  void clearAll() {
    _tokens.clear();
    _cur = '0';
    _error = null;
    _justEvaluated = false;
    _curAsPercentText = null;
    _lastStrip = null;
  }

  /// Tar emot alla knapptyper från UI.
  ///
  /// Tillåtna `v`:
  /// - '0'–'9'
  /// - ',' eller '.'
  /// - '±'
  /// - '%'
  /// - 'C'  (kort tryck = backspace)
  /// - '=', '+', '-', '−', '×', '÷', '*', '/'
  void input(String v) {
    // Om vi är i error-läge: låt C eller en siffra börja om.
    if (_error != null) {
      if (v == 'C' || _isDigit(v) || v == ',' || v == '.') {
        clearAll();
      } else {
        return; // ignorera annat
      }
    }

    // Normalisera decimal
    if (v == ',') v = '.';

    // Normalisera operator (om det är en)
    final op = _normOp(v); // '+', '-', '*', '/', eller null

    // Siffror
    if (_isDigit(v)) {
      _pushDigit(v);
      return;
    }

    // Decimalpunkt
    if (v == '.') {
      _pushDot();
      return;
    }

    // Byt tecken
    if (v == '±') {
      _toggleSign();
      return;
    }

    // Procent
    if (v == '%') {
      _applyPercent();
      return;
    }

    // Lika med
    if (v == '=') {
      _commitEquals();
      return;
    }

    // Kort tryck på C = backspace
    if (v == 'C') {
      _shortClear();
      return;
    }

    // Operatorer
    if (op != null) {
      _commitOperator(op);
      return;
    }

    // Okänd input ignoreras
  }

  // ======== Inmatnings-hjälpare ========

  void _pushDigit(String d) {
    _curAsPercentText = null;

    // Efter '=', ny siffra börjar nytt uttryck
    if (_justEvaluated) {
      _tokens.clear();
      _cur = '0';
      _justEvaluated = false;
      _lastStrip = null;
    }

    // Begränsa heltals- och totalsiffror
    final intDigits = _countIntDigits(_cur);
    final hasDot = _cur.contains('.');
    if (!hasDot && intDigits >= _maxIntDigits) return;

    final totalDigits = _countDigits(_cur);
    if (totalDigits >= _maxTotalDigits) return;

    if (_cur == '0') {
      _cur = d;
    } else {
      _cur += d;
    }
  }

  void _pushDot() {
    _curAsPercentText = null;

    if (_justEvaluated) {
      _tokens.clear();
      _cur = '0';
      _justEvaluated = false;
      _lastStrip = null;
    }

    if (!_cur.contains('.')) {
      _cur += (_cur.isEmpty ? '0.' : '.');
    }
  }

  void _toggleSign() {
    if (_cur == '0') return;

    if (_cur.startsWith('-')) {
      _cur = _cur.substring(1);
    } else {
      _cur = '-$_cur';
    }

    // Håll ev. procenttext i synk
    if (_curAsPercentText != null) {
      if (_cur.startsWith('-') && !_curAsPercentText!.startsWith('-')) {
        _curAsPercentText = '-${_curAsPercentText!}';
      } else if (!_cur.startsWith('-') && _curAsPercentText!.startsWith('-')) {
        _curAsPercentText = _curAsPercentText!.substring(1);
      }
    }
  }

  void _applyPercent() {
    final b = _toDouble(_cur);
    if (b == null) return;

    // Kontext: [..., Num(a), Op(op)] + current b
    if (_tokens.length >= 2 &&
        _tokens[_tokens.length - 2] is _NumTok &&
        _tokens.last is _OpTok) {
      final a = (_tokens[_tokens.length - 2] as _NumTok).value;
      final op = (_tokens.last as _OpTok).op;

      double newCurrent;
      switch (op) {
        case '+':
        case '-':
          // a + b% => a + a*(b/100)
          // a - b% => a - a*(b/100)
          newCurrent = a * (b / 100.0);
          break;
        case '*':
          // a * b% => a * (b/100)
          newCurrent = (b / 100.0);
          break;
        case '/':
          // a / b% => a / (b/100)
          newCurrent = (b / 100.0);
          break;
        default:
          newCurrent = b / 100.0;
      }

      if (_invalidNum(newCurrent)) {
        _error = 'err';
        return;
      }

      _cur = _toPlain(newCurrent);
      _curAsPercentText = '${_stripZeros(_toPlain(b))} %';
      _justEvaluated = false;
      return;
    }

    // Ingen operator-kontekst: b% => b/100
    final newCurrent = b / 100.0;
    if (_invalidNum(newCurrent)) {
      _error = 'err';
      return;
    }

    _cur = _toPlain(newCurrent);
    _curAsPercentText = '${_stripZeros(_toPlain(b))} %';
    _justEvaluated = false;
  }

  void _shortClear() {
    // Kort tryck på C = backspace / återställ current
    _curAsPercentText = null;

    if (_justEvaluated) {
      // Efter '=': C nollställer bara current
      _cur = '0';
      _justEvaluated = false;
      return;
    }

    if (_cur.length <= 1 || (_cur.length == 2 && _cur.startsWith('-'))) {
      _cur = '0';
    } else {
      _cur = _cur.substring(0, _cur.length - 1);
    }
  }

  void _commitOperator(String op) {
    _curAsPercentText = null;

    final d = _toDouble(_cur);

    // Ingen current → byt bara operator om det redan finns en
    if (d == null || (_cur == '0' && _curAsPercentText == null && !_justEvaluated)) {
      if (_tokens.isNotEmpty && _tokens.last is _OpTok) {
        _tokens[_tokens.length - 1] = _OpTok(op);
      }
      return;
    }

    // Inget i tokens: lägg in current + operator
    if (_tokens.isEmpty) {
      _tokens
        ..add(_NumTok(d))
        ..add(_OpTok(op));
      _cur = '';
      _justEvaluated = false;
      return;
    }

    // Tokens slutar med operator → lägg in current + ny operator
    if (_tokens.last is _OpTok) {
      _tokens
        ..add(_NumTok(d))
        ..add(_OpTok(op));
      _cur = '';
      _justEvaluated = false;
      return;
    }

    // Tokens slutar med tal → lägg bara till operator
    _tokens.add(_OpTok(op));
    _cur = '';
    _justEvaluated = false;
  }

  void _commitEquals() {
    if (_tokens.isEmpty && _cur.isEmpty) return;

    // Bygg sekvens tokens + ev current
    final seq = <_Tok>[..._tokens];

    final d = _toDouble(_cur);
    if (seq.isEmpty) {
      if (d == null) return;
      seq.add(_NumTok(d));
    } else {
      if (seq.last is _OpTok) {
        // Slutar på operator → lägg med current om den är meningsfull,
        // annars ta bort hängande operator.
        final hasMeaningfulCurrent =
            _curAsPercentText != null ||
            (d != null && !(_cur == '0' && !_justEvaluated));
        if (hasMeaningfulCurrent && d != null) {
          seq.add(_NumTok(d));
        } else {
          seq.removeLast();
        }
      } else if (d != null && _cur.isNotEmpty) {
        // Slutar på tal och vi har ett nytt current → lägg med det sista talet
        seq.add(_NumTok(d));
      }
    }

    if (seq.isEmpty) return;

    final val = _evaluate(seq);
    if (val == null || _exceedsLimit(val)) {
      _error = 'err';
      _lastStrip = null;
      return;
    }

    // Bygg t.ex. "20 + 3 × 2 = 26"
    final exprText = _sequenceToStrip(seq);
    final resultText = _stripZeros(_toPlain(val));
    _lastStrip = '$exprText = $resultText';

    // Efter '=' börjar vi om: visa resultatet som ny current.
    _tokens.clear();
    _cur = _toPlain(val);
    _curAsPercentText = null;
    _justEvaluated = true;
  }

  // ======== Live-preview (tokens + current) ========

  double? _evalPreview() {
    if (_error != null) return null;

    // Inga tokens alls → bara current
    if (_tokens.isEmpty) {
      final d = _toDouble(_cur);
      return d;
    }

    // Börja med en kopia av tokens
    final seq = <_Tok>[..._tokens];

    final d = _toDouble(_cur);
    final hasMeaningfulCurrent =
        _curAsPercentText != null ||
        (d != null && !(_cur == '0' && !_justEvaluated));

    if (seq.isNotEmpty && seq.last is _OpTok) {
      if (hasMeaningfulCurrent) {
        // Ex: 20 + 3 × 2 → tokens: [20, +, 3, ×], cur: "2"
        seq.add(_NumTok(d ?? 0));
      } else {
        // Ex: 20 + 3 × → visa 20 + 3 (ta bort sista operatorn)
        seq.removeLast();
      }
    } else {
      // Slutar på tal: oftast har vi redan allt i tokens
      // Vi lägger inte till current igen för att undvika dubletter.
    }

    if (seq.isEmpty) return null;

    final val = _evaluate(seq);
    if (val == null || _invalidNum(val) || _exceedsLimit(val)) return null;
    return val;
  }

  // ======== Remsan ========

  String _sequenceToStrip(List<_Tok> seq) {
    final buf = StringBuffer();
    for (final t in seq) {
      if (t is _NumTok) {
        buf.write(_stripZeros(_toPlain(t.value)));
      } else if (t is _OpTok) {
        buf.write(' ${_prettyOp(t.op)} ');
      }
    }
    return buf.toString();
  }

  String _buildStrip() {
    if (_error != null) return '';

    // Direkt efter '=': tokens är tomma men vi vill visa "a + b × c = d"
    if (_tokens.isEmpty && _justEvaluated) {
      return _lastStrip ?? '';
    }

    final buf = StringBuffer();
    buf.write(_sequenceToStrip(_tokens));

    // Current-del (sista talet som håller på att skrivas)
    if (_tokens.isNotEmpty) {
      if (_curAsPercentText != null) {
        buf.write(_curAsPercentText);
      } else {
        final d = _toDouble(_cur);
        if (d != null && !(_cur == '0' && !_justEvaluated)) {
          buf.write(_stripZeros(_toPlain(d)));
        }
      }
    }

    return buf.toString();
  }

  // ======== Utvärdering (Shunting-yard + RPN) ========

  double? _evaluate(List<_Tok> infix) {
    if (infix.isEmpty) return null;

    // 1) Infix -> RPN (shunting yard)
    final out = <_Tok>[];
    final ops = <_OpTok>[];

    for (final t in infix) {
      if (t is _NumTok) {
        out.add(t);
      } else if (t is _OpTok) {
        while (ops.isNotEmpty && _prec(ops.last.op) >= _prec(t.op)) {
          out.add(ops.removeLast());
        }
        ops.add(t);
      }
    }

    while (ops.isNotEmpty) {
      out.add(ops.removeLast());
    }

    // 2) RPN-eval
    final st = <double>[];
    for (final t in out) {
      if (t is _NumTok) {
        st.add(t.value);
      } else if (t is _OpTok) {
        if (st.length < 2) return null;
        final b = st.removeLast();
        final a = st.removeLast();
        double r;

        switch (t.op) {
          case '+':
            r = a + b;
            break;
          case '-':
            r = a - b;
            break;
          case '*':
            r = a * b;
            break;
          case '/':
            if (b == 0) return null;
            r = a / b;
            break;
          default:
            return null;
        }

        if (_invalidNum(r) || _exceedsLimit(r)) return null;
        st.add(r);
      }
    }

    if (st.length != 1) return null;
    return st.last;
  }

  // ======== Småhjälpare ========

  static bool _isDigit(String v) =>
      v.length == 1 && v.codeUnitAt(0) >= 48 && v.codeUnitAt(0) <= 57;

  static String? _normOp(String v) {
    switch (v) {
      case '+':
        return '+';
      case '−':
      case '-':
        return '-';
      case '×':
      case '*':
        return '*';
      case '÷':
      case '/':
        return '/';
    }
    return null;
  }

  static String _prettyOp(String op) {
    switch (op) {
      case '+':
        return '+';
      case '-':
        return '−';
      case '*':
        return '×';
      case '/':
        return '÷';
    }
    return op;
  }

  static int _prec(String op) {
    if (op == '+' || op == '-') return 1;
    if (op == '*' || op == '/') return 2;
    return 0;
  }

  static bool _invalidNum(double v) => v.isNaN || !v.isFinite;

  static bool _exceedsLimit(num v) => v.abs() > _maxSafeInt;

  static int _countDigits(String s) =>
      s.replaceAll(RegExp(r'[^0-9]'), '').length;

  static int _countIntDigits(String s) {
    final dot = s.indexOf('.');
    final end = dot == -1 ? s.length : dot;
    final intPart = s.substring(0, end).replaceAll(RegExp(r'[^0-9]'), '');
    return intPart.length;
  }

  static double? _toDouble(String s) {
    if (s.isEmpty || s == '-' || s == '+') return null;
    try {
      return double.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String _toPlain(double v) {
    // Undvik vetenskaplig notation & trimma onödiga nollor.
    String s = v.toStringAsFixed(12);
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s.isEmpty ? '0' : s;
  }

  /// Formaterar för stora displayen:
  /// - heltal utan .0
  /// - tusental med smalt mellanrum (U+202F)
  static String _fmt(double v) {
    String base;
    if (v == v.roundToDouble()) {
      base = v.toInt().toString();
    } else {
      base = _toPlain(v);
    }

    final negative = base.startsWith('-');
    var s = negative ? base.substring(1) : base;

    String intPart;
    String fracPart = '';
    final dotIndex = s.indexOf('.');
    if (dotIndex == -1) {
      intPart = s;
    } else {
      intPart = s.substring(0, dotIndex);
      fracPart = s.substring(dotIndex); // inkl punkt
    }

    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      buf.write(intPart[i]);
      final remaining = intPart.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buf.write('\u202F'); // smalt mellanrum
      }
    }

    final grouped = buf.toString() + fracPart;
    return negative ? '-$grouped' : grouped;
  }

  static String _stripZeros(String s) {
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'\.?0+$'), '');
      if (s.isEmpty || s == '-' || s == '+') return '0';
    }
    return s;
  }
}

// ======== Token-typer ========

abstract class _Tok {}

class _NumTok extends _Tok {
  final double value;
  _NumTok(this.value);
}

class _OpTok extends _Tok {
  final String op; // '+','-','*','/'
  _OpTok(this.op);
}