// lib/logic/calculator_engine.dart
import 'package:intl/intl.dart';

/// Enkel miniräknarmotor med tokens, operatorprioritet, procent och live-preview.
class CalculatorEngine {
  // ===== Publika API =====
  String get display {
    if (_error != null) return 'Error';
    final p = _evalPreview();
    if (p != null) return _fmt(p);
    return _cur.isEmpty ? '0' : _cur;
  }

  /// Remsan under displayen – uttrycket i snygg form.
  String get strip => _buildStrip();

  /// Tar emot knapptryck.
  void input(String v) {
    if (_error != null) _error = null; // reset fel på ny input

    // Normalisera vissa symboler
    if (v == '×') v = '*';
    if (v == '÷') v = '/';
    if (v == '−') v = '-';
    if (v == ',') v = '.'; // internt jobbar vi med punkt

    // Siffror
    if (_digits.contains(v)) {
      if (_cur == '0') {
        _cur = v; // ersätt ledande 0
      } else {
        _cur += v;
      }
      return;
    }

    // Decimal
    if (v == '.') {
      if (_cur.isEmpty) {
        _cur = '0.';
      } else if (!_cur.contains('.')) {
        _cur += '.';
      }
      return;
    }

    // Procent = markera att aktuellt tal är procent av vänster operand
    if (v == '%') {
      if (_cur.isEmpty) return; // inget att markera
      _curIsPercent = true;
      return;
    }

    // Backspace
    if (v == 'C') {
      if (_cur.isNotEmpty) {
        _cur = _cur.substring(0, _cur.length - 1);
        if (_cur.isEmpty) _curIsPercent = false;
      } else if (_tokens.isNotEmpty) {
        // Ta bort sista operatorn om uttrycket slutar på operator
        if (_tokens.last is _OpTok) _tokens.removeLast();
      }
      return;
    }

    // Lika med => beräkna och förbered för vidare räkning
    if (v == '=') {
      final seq = <_Tok>[..._tokens];
      final n = _currentNumTok();
      if (n != null) seq.add(n);
      final res = _safeEvaluate(seq);
      if (res == null) {
        _error = 'E';
        return;
      }
      _tokens.clear();
      _cur = _toUserString(res); // gör resultat redigerbart
      _curIsPercent = false;
      return;
    }

    // Operatorer
    if (_ops.contains(v)) {
      // Om det redan fanns operator sist: ersätt den (ändra åsikt)
      if (_tokens.isNotEmpty && _tokens.last is _OpTok && _cur.isEmpty) {
        _tokens[_tokens.length - 1] = _OpTok(v);
        return;
      }

      final n = _currentNumTok();
      if (n != null) {
        _tokens.add(n);
      } else if (_tokens.isEmpty) {
        // Om inget tal alls, tillåt ledande minus för negativt tal
        if (v == '-') {
          _cur = '-';
          return;
        }
        // Annars ignorera operator
        return;
      }

      _tokens.add(_OpTok(v));
      _cur = '';
      _curIsPercent = false;
      return;
    }

    // Övrigt ignoreras
  }

  /// Långtryck på C kopplat från UI.
  void clearAll() => _clearAll();

  // ======= Intern status =======
  final List<_Tok> _tokens = [];
  String _cur = '';
  bool _curIsPercent = false;
  String? _error;

  // formatter för display (svensk)
  final NumberFormat _nf = NumberFormat('#,##0.########', 'sv_SE');

  // ======= Hjälpmetoder =======

  static const Set<String> _digits = {
    '0','1','2','3','4','5','6','7','8','9',
  };

  static const Set<String> _ops = {'+','-','*','/'};

  void _clearAll() {
    _tokens.clear();
    _cur = '';
    _curIsPercent = false;
    _error = null;
  }

  _NumTok? _currentNumTok() {
    // Tomt eller bara "-" räknas inte som tal
    if (_cur.isEmpty || _cur == '-') return null;

    var s = _cur;
    // Ta bort avslutande decimalpunkt
    if (s.endsWith('.')) s = '${s}0';

    final d = double.tryParse(s);
    if (d == null) return null;
    return _NumTok(d, isPercent: _curIsPercent);
  }

  String _fmt(double v) => _nf.format(v);

  String _toUserString(double v) {
    // Skriv i "intern" form för vidare redigering (punkt som decimal)
    // men utan onödig .0 om heltal
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  // Bygger remsan av tokens + ev. current
  String _buildStrip() {
    if (_error != null) return '';
    final seq = <_Tok>[..._tokens];
    final n = _currentNumTok();
    if (n != null) seq.add(n);

    if (seq.isEmpty) return '';
    final b = StringBuffer();
    for (final t in seq) {
      if (t is _NumTok) {
        b.write(_fmt(t.value));
        if (t.isPercent) b.write(' %');
      } else if (t is _OpTok) {
        b.write(' ');
        b.write(_prettyOp(t.op));
        b.write(' ');
      }
    }
    return b.toString();
  }

  String _prettyOp(String op) {
    switch (op) {
      case '*': return '×';
      case '/': return '÷';
      case '-': return '−';
      default:  return op;
    }
  }

// Live preview: visa senaste värde även när uttrycket slutar med operator,
// och räkna live så fort användaren skriver nästa tal.
double? _evalPreview() {
  final base = List<_Tok>.from(_tokens);
  final curTok = _currentNumTok();

  // Inget tidigare uttryck? Visa bara current (om något).
  if (base.isEmpty) {
    return curTok?.value;
  }

  final endsWithOp = base.isNotEmpty && base.last is _OpTok;

  if (endsWithOp) {
    if (curTok != null) {
      // ...operator + current => räkna tokens + current
      final seq = [...base, curTok];
      return _safeEvaluate(seq);
    } else {
      // ...operator men inget current ännu => visa värdet "hittills"
      final seq = List<_Tok>.from(base)..removeLast(); // ta bort trailing op
      return _safeEvaluate(seq);
    }
  }

  // Slutar inte med operator:
  // Om det finns current (borde inte normalt), räkna med det – annars med tokens.
  if (curTok != null) {
    final seq = [...base, curTok];
    return _safeEvaluate(seq);
  } else {
    return _safeEvaluate(base);
  }
}

  // ----- Evaluering med operatorprioritet -----
  // Shunting-yard → RPN → utvärdera.
  double _evaluate(List<_Tok> seq) {
    // 1) Infix → RPN
    final out = <_Tok>[];
    final ops = <_OpTok>[];
    for (final t in seq) {
      if (t is _NumTok) {
        out.add(t);
      } else if (t is _OpTok) {
        while (ops.isNotEmpty &&
            _precedence(ops.last.op) >= _precedence(t.op)) {
          out.add(ops.removeLast());
        }
        ops.add(t);
      }
    }
    while (ops.isNotEmpty) {
      out.add(ops.removeLast());
    }

    // 2) RPN → resultat
    final st = <_NumTok>[];
    for (final t in out) {
      if (t is _NumTok) {
        st.add(t);
        continue;
      }
      if (t is _OpTok) {
        if (st.length < 2) throw StateError('RPN underflow');
        final b = st.removeLast();
        final a = st.removeLast();
        final res = _applyOp(a.value, t.op, b.value, bIsPercent: b.isPercent);
        st.add(_NumTok(res));
      }
    }
    if (st.length != 1) throw StateError('RPN stack mismatch');
    return st.single.value;
  }

  // ===== Helper: safe evaluate (fångar fel) =====
  double? _safeEvaluate(List<_Tok> seq) {
    try {
      final v = _evaluate(seq);
      if (v.isNaN || v.isInfinite) return null;
      return v;
    } catch (_) {
      return null;
    }
  }

  int _precedence(String op) => (op == '+' || op == '-') ? 1 : 2;

  double _applyOp(double a, String op, double b, {required bool bIsPercent}) {
    // Procentregler enligt specifikation
    if (bIsPercent) {
      switch (op) {
        case '+':
          return a + a * (b / 100.0);
        case '-':
          return a - a * (b / 100.0);
        case '*':
          return a * (b / 100.0);
        case '/':
          final div = b / 100.0;
          if (div == 0) throw StateError('Divide by zero');
          return a / div;
      }
    }

    // Vanliga operationer
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        if (b == 0) throw StateError('Divide by zero');
        return a / b;
    }
    throw StateError('Unknown op $op');
  }
}

// ===== Tokens =====
abstract class _Tok {}

class _NumTok extends _Tok {
  final double value;
  final bool isPercent;
  _NumTok(this.value, {this.isPercent = false});
}

class _OpTok extends _Tok {
  final String op; // '+', '-', '*', '/'
  _OpTok(this.op);
}