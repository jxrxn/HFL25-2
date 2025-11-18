// lib/logic/calculator_engine.dart
import 'package:decimal/decimal.dart';

class CalculatorEngine {
  // ===== Gränser =====
  static const int _maxSigDigits = 15;            // max signifikanta siffror
  static final Decimal _maxAbs =
      Decimal.parse('999999999999999');           // gräns i Decimal

  /// Hjälp: gör en exakt division a/b och får tillbaka Decimal.
  static Decimal _divDecimal(Decimal a, Decimal b) {
    // Gör om till Rational först
    final r = a.toRational() / b.toRational();
    // Tillbaka till Decimal med begränsad precision
    return r.toDecimal(
      scaleOnInfinitePrecision: _maxSigDigits,
    );
  }

  // ===== Intern state =====
  final List<_Tok> _tokens = <_Tok>[]; // infix: Num, Op, Num, Op, ...
  String _cur = '0'; // pågående tal som text
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
    // 1) Error-läge
    if (_error != null) return 'Error';

    // 2) Försök live-preview av hela uttrycket,
    //    MEN hoppa över om vi är mitt i en hängande decimal (1., -., osv).
    final hasHangingDot =
        _cur == '.' || _cur == '-.' || (_cur.endsWith('.') && _cur.length > 1);

    final preview = _evalPreview();
    if (preview != null && !hasHangingDot) {
      return _fmt(preview);
    }

    // 3) Om inget preview (eller vi har hängande decimal), visa _cur.

    // Tomt → visa 0
    if (_cur.isEmpty) return '0';

    // Specialfall: bara punkt
    if (_cur == '.') return '0.';

    // Specialfall: negativt tal där bara '-' och '.' är inskrivna
    if (_cur == '-.') return '-0.';

    // Om vi har t.ex. "1." eller "1234.", visa precis så.
    if (_cur.endsWith('.') && _cur.length > 1) {
      return _cur;
    }

    // 4) Vanligt fall: försök tolka _cur som Decimal och formatera snyggt.
    final d = _toDecimal(_cur);
    if (d != null) {
      return _fmt(d);
    }

    // 5) Fallback: om _cur inte går att parse:a (ska nästan aldrig hända)
    return _cur;
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
    // Om vi är i error-läge: låt C eller en siffra (eller decimal) börja om.
    if (_error != null) {
      if (v == 'C' || _isDigit(v) || v == ',' || v == '.') {
        clearAll();
      } else {
        return; // ignorera annat tills man "bryter sig ur" med C/siffra
      }
    }

    // Normalisera decimal
    if (v == ',') v = '.';

    // Normalisera operator (om det är en)
    final op = _normOp(v); // '+', '-', '*', '/', eller null

    // ===== Siffror =====
    if (_isDigit(v)) {
      _pushDigit(v);
      return;
    }

    // ===== Decimalpunkt =====
    if (v == '.') {
      _pushDot();
      return;
    }

    // ===== Byt tecken =====
    if (v == '±') {
      _toggleSign();
      return;
    }

    // ===== Procent =====
    if (v == '%') {
      _applyPercent();
      return;
    }

    // ===== Lika med =====
    if (v == '=') {
      _commitEquals();
      return;
    }

    // ===== Kort tryck på C = backspace =====
    if (v == 'C') {
      _shortClear();
      return;
    }

    // ===== Operatorer =====
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

    // Begränsa totala antalet siffror (heltal + decimal)
    final sigDigits = _countDigits(_cur);
    if (sigDigits >= _maxSigDigits) return;

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
    final b = _toDecimal(_cur);
    if (b == null) return;

    final hundred = Decimal.fromInt(100);

    // Kontext: [..., Num(a), Op(op)] + current b
    if (_tokens.length >= 2 &&
        _tokens[_tokens.length - 2] is _NumTok &&
        _tokens.last is _OpTok) {
      final a = (_tokens[_tokens.length - 2] as _NumTok).value;
      final op = (_tokens.last as _OpTok).op;

      // b som andel (b/100) räknat exakt, men tillbaka till Decimal
      final bFrac = _divDecimal(b, hundred);

      Decimal newCurrent;
      switch (op) {
        case '+':
        case '-':
          // a + b% => a + a*(b/100)
          // a - b% => a - a*(b/100)
          newCurrent = a * bFrac;
          break;
        case '*':
          // a * b% => a * (b/100)
          newCurrent = bFrac;
          break;
        case '/':
          // a / b% => a / (b/100) hanteras av att uttrycket blir a ÷ (b/100)
          // så även här använder vi bara bFrac som “nuvarande tal”
          newCurrent = bFrac;
          break;
        default:
          newCurrent = bFrac;
      }

      if (_exceedsLimit(newCurrent)) {
        _error = 'err';
        return;
      }

      _cur = _toPlain(newCurrent);
      _curAsPercentText = '${_stripZeros(_toPlain(b))} %';
      _justEvaluated = false;
      return;
    }

    // Ingen operator-kontekst: b% => b/100
    final newCurrent = _divDecimal(b, hundred);
    if (_exceedsLimit(newCurrent)) {
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

    final d = _toDecimal(_cur);

    // Ingen current → byt bara operator om det redan finns en
    if (d == null ||
        (_cur == '0' && _curAsPercentText == null && !_justEvaluated)) {
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

    // Bygg sekvens tokens + ev current (för själva beräkningen)
    final seq = <_Tok>[..._tokens];
    final d = _toDecimal(_cur);

    if (seq.isEmpty) {
      if (d == null) return;
      seq.add(_NumTok(d));
    } else {
      if (seq.last is _OpTok) {
        // Slutar på operator → lägg med current om den är meningsfull,
        // annars ta bort hängande operator.
        final hasMeaningfulCurrent =
            _curAsPercentText != null || d != null;
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

    // ===== Bygg remsa med mänsklig text (inkl. %, tusental) =====
    // Basen: tokens (utan current)
    final exprBuf = StringBuffer();
    exprBuf.write(_sequenceToStrip(_tokens));

    // Lägg till current-delen så som den visats för användaren:
    // - om vi är i procent-läge → "10 %"
    // - annars det sista talet, utan extra .0
    if (_tokens.isNotEmpty) {
      if (_curAsPercentText != null) {
        exprBuf.write(_curAsPercentText); // t.ex. "10 %"
      } else if (d != null && !(_cur == '0' && !_justEvaluated)) {
        exprBuf.write(_stripZeros(_toPlain(d))); // t.ex. "2" eller "0.1"
      }
    }

    final exprText = exprBuf.toString();

    // Resultatet formateras med tusentalsavgränsare
    _lastStrip = '$exprText = ${_fmt(val)}';

    // Efter '=' börjar vi om: visa resultatet som ny current.
    _tokens.clear();
    _cur = _toPlain(val);
    _curAsPercentText = null;
    _justEvaluated = true;
  }

// ======== Live-preview (tokens + current) ========
Decimal? _evalPreview() {
  if (_error != null) return null;

  // Inga tokens alls → bara current
  if (_tokens.isEmpty) {
    final d = _toDecimal(_cur);
    return d;
  }

  // Börja med en kopia av tokens
  final seq = <_Tok>[..._tokens];

  final d = _toDecimal(_cur);
  final hasMeaningfulCurrent = _curAsPercentText != null ||
      (d != null && !(_cur == '0' && !_justEvaluated));

  if (seq.isNotEmpty && seq.last is _OpTok) {
    if (hasMeaningfulCurrent) {
      // Ex: 20 + 3 × 2 → tokens: [20, +, 3, ×], cur: "2"
      seq.add(_NumTok(d ?? Decimal.zero));
    } else {
      // Ex: 20 + 3 × → visa 20 + 3 (ta bort sista operatorn)
      seq.removeLast();
    }
  } else {
    // Slutar på tal: oftast har vi redan allt i tokens.
    // Extra specialfall: om vi har en procenttext aktiv men inget nytt tal,
    // kan vi behöva lägga till värdet som tal i sekvensen.
    if (_curAsPercentText != null && d != null) {
      // Se till att inte lägga in dubbelt om seq redan slutar med samma värde.
      if (seq.isEmpty || !(seq.last is _NumTok && (seq.last as _NumTok).value == d)) {
        seq.add(_NumTok(d));
      }
    }
  }

  if (seq.isEmpty) return null;

  // 🔹 SPECIALFALL: "… ÷ 0" i live-preview
  // Om sekvensen slutar med Op('/') följt av Num(0) → avbryt bara preview
  if (seq.length >= 2 &&
      seq[seq.length - 1] is _NumTok &&
      seq[seq.length - 2] is _OpTok) {
    final lastNum = seq.last as _NumTok;
    final lastOp  = seq[seq.length - 2] as _OpTok;

    if (lastOp.op == '/' && lastNum.value == Decimal.zero) {
      // Användaren har skrivit a ÷ 0, men kanske är på väg mot 0,2
      // → ingen Error ännu, bara ingen live-preview.
      return null;
    }
  }

  final val = _evaluate(seq);  // OBS: samma som du hade innan
  if (val == null || _exceedsLimit(val)) return null;
  return val;
}

  // ======== Remsan ========

  String _sequenceToStrip(List<_Tok> seq) {
    final buf = StringBuffer();
    for (final t in seq) {
      if (t is _NumTok) {
        // Samma logik som tidigare, men byt . → , för visning
        final plain = _stripZeros(_toPlain(t.value));
        buf.write(plain.replaceAll('.', ','));
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

    // 1) Inga tokens ännu ⇒ vi är i första talet / första procenten
    if (_tokens.isEmpty) {
      // a) Pågående procentläge: visa t.ex. "10 %"
      if (_curAsPercentText != null) {
        return _curAsPercentText!;
      }

      // b) Specialfall: användaren har tryckt komma men ingen decimalsiffra än
      if (_cur == '.') return '0,';
      if (_cur == '-.') return '-0,';
      if (_cur.endsWith('.') && _cur.length > 1) {
        // Ex: "1." eller "1234."
        return _cur.replaceAll('.', ',');
      }

      // c) Vanligt tal: visa det så fort det inte bara är "0"
      if (_cur.isEmpty || _cur == '0') {
        return '';
      }

      final d = _toDecimal(_cur);
      if (d == null) return '';

      final plain = _stripZeros(_toPlain(d));
      return plain.replaceAll('.', ',');
    }

    // 2) Det finns tokens ⇒ bygg upp "a + b × ..." + current-del
    final buf = StringBuffer();
    buf.write(_sequenceToStrip(_tokens));

    if (_tokens.isNotEmpty) {
      if (_curAsPercentText != null) {
        // t.ex. "10 %"
        buf.write(_curAsPercentText);
      } else {
        // Specialfall: komma utan decimalsiffra även här
        if (_cur == '.') {
          buf.write('0,');
        } else if (_cur == '-.') {
          buf.write('-0,');
        } else if (_cur.endsWith('.') && _cur.length > 1) {
          buf.write(_cur.replaceAll('.', ','));
        } else {
          final d = _toDecimal(_cur);
          if (d != null && !(_cur == '0' && !_justEvaluated)) {
            final plain = _stripZeros(_toPlain(d));
            buf.write(plain.replaceAll('.', ','));
          }
        }
      }
    }

    return buf.toString();
  }

  // ======== Utvärdering (Shunting-yard + RPN) ========

  Decimal? _evaluate(List<_Tok> infix) {
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
    final st = <Decimal>[];
    for (final t in out) {
      if (t is _NumTok) {
        st.add(t.value);
      } else if (t is _OpTok) {
        if (st.length < 2) return null;
        final b = st.removeLast();
        final a = st.removeLast();
        late Decimal r;

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
            if (b == Decimal.zero) {
              // Division med noll ska sätta error direkt (även i live-preview).
              _error = 'err';
              return null;
            }
            r = _divDecimal(a, b);
          break;
          default:
            return null;
        }

        if (_exceedsLimit(r)) return null;
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

  static int _countDigits(String s) =>
      s.replaceAll(RegExp(r'[^0-9]'), '').length;

  static Decimal? _toDecimal(String s) {
    if (s.isEmpty || s == '-' || s == '+') return null;
    try {
      return Decimal.parse(s);
    } catch (_) {
      return null;
    }
  }

  static bool _exceedsLimit(Decimal v) => v.abs() > _maxAbs;

  static String _toPlain(Decimal v) {
    var s = v.toString();
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    if (s.isEmpty || s == '-' || s == '+') return '0';
    return s;
  }

  /// Formaterar för stora displayen:
  /// - heltal utan .0
  /// - tusental med smalt mellanrum (U+202F)
  static String _fmt(Decimal v) {
    final base = _toPlain(v);

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
  final Decimal value;
  _NumTok(this.value);
}

class _OpTok extends _Tok {
  final String op; // '+','-','*','/'
  _OpTok(this.op);
}