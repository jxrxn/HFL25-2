// lib/logic/calculator_engine.dart
import 'package:decimal/decimal.dart';

class CalculatorEngine {
  // ===== Gränser =====
  static const int _maxSigDigits = 27;            // max signifikanta siffror
  static final Decimal _maxAbs =
      Decimal.parse('999999999999999999999999999');           // gräns i Decimal

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

  /// Det som visas i stora displayen (live-resultat / inmatning).
  String get display {
    // 1) Error-läge
    if (_error != null) return 'Error';

    // 2) Kolla om vi är mitt i en "hängande" decimal
    //    – men bara när vi skriver första talet (inga tokens än).
    //    Efter en operator (andra talet) vill vi gärna behålla live-preview
    //    tills användaren börjar skriva riktiga siffror.
    final bool hasHangingDot =
        _tokens.isEmpty &&
        (_cur == '.' ||
         _cur == '-.' ||
         (_cur.endsWith('.') && _cur.length > 1));

    // 3) Försök räkna ut live-preview av uttrycket
    final preview = _evalPreview();

    // Visa live-resultat *bara* när:
    // - vi inte har en hängande decimal, och
    // - det finns ett riktigt uttryck (tokens) eller vi nyss tryckt '='
    if (preview != null &&
        !hasHangingDot &&
        (_tokens.isNotEmpty || _justEvaluated)) {
      return _fmt(preview);
    }

    // 4) Annars: visa pågående inmatning snyggt formatterad
    // (behåller alla decimalsiffror + tusentalsmellanrum)
    return _formatInputForDisplay(_cur);
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
      final d = _toDecimalLenient(_cur);
      return d;
    }

    // Börja med en kopia av tokens
    final seq = <_Tok>[..._tokens];

    // Tolka pågående inmatning lite snällare (klarar "0.", ".5", "-.5" etc)
    final d = _toDecimalLenient(_cur);

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
      // Slutar på tal. Om vi är i ett procentläge kan vi behöva lägga till
      // det tolkade percent-värdet som nytt tal i sekvensen.
      if (_curAsPercentText != null && d != null) {
        if (seq.isEmpty ||
            !(seq.last is _NumTok &&
              (seq.last as _NumTok).value == d)) {
          seq.add(_NumTok(d));
        }
      }
    }

    if (seq.isEmpty) return null;

    // --- Ny logik: hantera "a * 0," och "a ÷ 0," i live-preview ---
    if (seq.length >= 2 &&
        seq[seq.length - 1] is _NumTok &&
        seq[seq.length - 2] is _OpTok) {
      final lastNum = seq.last as _NumTok;
      final lastOp  = seq[seq.length - 2] as _OpTok;

      // Hjälp: avgör om current-texten fortfarande betyder exakt 0
      bool isZeroCurrent() {
        if (_cur.isEmpty) return false;
        // internt använder vi redan '.' men vi gör det robust ändå
        final normalized = _cur.replaceAll(',', '.');
        final dec = _toDecimalLenient(normalized);
        return dec != null && dec == Decimal.zero;
      }

      // Fall:
      //  - tokens representerar första "a op" (t.ex. 333 ÷)
      //  - current är fortfarande nån variant av 0 (0, 0., 0.0 …)
      //  - op är * eller ÷
      //
      // Då vill vi i live-preview *ignorera* andra talet
      // och bara visa "a" tills användaren skriver en icke-noll decimal.
      if (isZeroCurrent() &&
          (lastOp.op == '*' || lastOp.op == '/') &&
          _tokens.length == 2) {
        // _tokens är då t.ex. [Num(a), Op(op)]
        final truncated = <_Tok>[..._tokens];

        // Plocka bort hängande operator så vi får bara första talet
        if (truncated.isNotEmpty && truncated.last is _OpTok) {
          truncated.removeLast();
        }

        if (truncated.isNotEmpty) {
          final leftVal = _evaluate(truncated);
          if (leftVal != null && !_exceedsLimit(leftVal)) {
            return leftVal;
          }
        }
      }

      // Safety: om vi ändå skulle hamna med ett riktigt "… ÷ 0"
      // (t.ex. via klistrad text) så slå bara av live-preview.
      if (lastOp.op == '/' && lastNum.value == Decimal.zero) {
        return null;
      }
    }

    final val = _evaluate(seq);
    if (val == null || _exceedsLimit(val)) return null;
    return val;
  }

  // ======== Remsan ========

  // Gruppera heltal med smalt mellanrum (U+202F): "12345" -> "12 345"
  String _groupIntString(String digits) {
    // Ta bort ledande nollor, men lämna minst en nolla kvar
    var s = digits.replaceFirst(RegExp(r'^0+(?!$)'), '');
    final len = s.length;
    if (len <= 3) return s;

    const thinSpace = '\u202F';

    final buf = StringBuffer();
    final firstGroupLen = len % 3 == 0 ? 3 : len % 3;

    buf.write(s.substring(0, firstGroupLen));
    for (var i = firstGroupLen; i < len; i += 3) {
      buf.write(thinSpace);
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  /// Formattera ett Decimal-värde för remsan:
  /// - grupperar heltalsdelen med mellanslag
  /// - byter '.' -> ',' som decimaltecken
  String _formatDecimalForStrip(Decimal d) {
    final plain = _stripZeros(_toPlain(d)); // t.ex. "12345.00" -> "12345"
    final parts = plain.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : '';

    final groupedInt = _groupIntString(intPart);

    if (fracPart.isEmpty) {
      return groupedInt;
    } else {
      return '$groupedInt,$fracPart';
    }
  }

  /// Formattera _cur textuellt för remsan:
  /// - behåller alla decimalsiffror (inkl. nollor)
  /// - grupperar heltalsdelen med mellanslag
  /// - byter '.' -> ',' som decimaltecken
  String _formatInputForStrip(String cur) {
    if (cur.isEmpty) return '';

    var neg = cur.startsWith('-');
    var s = neg ? cur.substring(1) : cur;

    final hasDot = s.contains('.');

    String intPart;
    String fracPart = '';

    if (hasDot) {
      final parts = s.split('.');
      intPart = parts[0].isEmpty ? '0' : parts[0];
      if (parts.length > 1) {
        // Behåll exakt det användaren skrivit efter punkten
        fracPart = parts[1];
      }
    } else {
      intPart = s.isEmpty ? '0' : s;
    }

    final groupedInt = _groupIntString(intPart);

    final buf = StringBuffer();
    if (neg && (groupedInt != '0' || hasDot || fracPart.isNotEmpty)) {
      buf.write('-');
    }
    buf.write(groupedInt);

    if (hasDot) {
      buf.write(',');      // svensk decimal
      buf.write(fracPart); // alla decimalsiffror, även nollor
    }

    return buf.toString();
  }

  String _sequenceToStrip(List<_Tok> seq) {
    const thinSpace = '\u202F';
    final buf = StringBuffer();
    for (final t in seq) {
      if (t is _NumTok) {
        buf.write(_formatDecimalForStrip(t.value));
      } else if (t is _OpTok) {
        // tidigare: ' ${_prettyOp(t.op)} '
        buf.write(thinSpace);
        buf.write(_prettyOp(t.op));
        buf.write(thinSpace);
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

      // b) Om det bara är "0" i början, visa inget i remsan
      //    (första nollan ska inte lägga sig på remsan)
      if (_cur.isEmpty || _cur == '0') {
        return '';
      }

      // c) Vanligt tal: formattera textuellt utifrån _cur
      return _formatInputForStrip(_cur);
    }

    // 2) Det finns tokens ⇒ bygg upp "a + b × ..." + current-del
    final buf = StringBuffer();
    buf.write(_sequenceToStrip(_tokens));

    if (_tokens.isNotEmpty) {
      if (_curAsPercentText != null) {
        // t.ex. "10 %"
        buf.write(_curAsPercentText);
      } else {
        // 🔹 Nytt: skriv ALLTID current, även "0"
        // (så "333 ÷ 0" och "333 × 0" syns direkt)
        if (_cur.isNotEmpty) {
          buf.write(_formatInputForStrip(_cur));
        }
      }
    }

    return buf.toString();
  }

    // === Display-helper ===
  // Använder samma logik som remsan, men faller tillbaka på '0' om resultatet är tomt.
  String _formatInputForDisplay(String cur) {
    final s = _formatInputForStrip(cur);
    return s.isEmpty ? '0' : s;
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

    /// Lite snällare parser som klarar "1.", ".5", "-.5" osv
  static Decimal? _toDecimalLenient(String s) {
    if (s.isEmpty || s == '-' || s == '+') return null;

    // "123." eller "-123." → tolka som "123" / "-123"
    if (s.endsWith('.') && s.length > 1) {
      final withoutDot = s.substring(0, s.length - 1);
      return _toDecimal(withoutDot);
    }

    // ".5" → "0.5"
    if (s.startsWith('.') && s.length > 1) {
      return _toDecimal('0$s');
    }

    // "-.5" → "-0.5"
    if (s.startsWith('-.') && s.length > 2) {
      return _toDecimal('-0${s.substring(2)}');
    }

    // Annars: vanlig tolkning
    return _toDecimal(s);
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