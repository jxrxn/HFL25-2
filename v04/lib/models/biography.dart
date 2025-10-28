class Biography {
  final String? fullName;
  final String? alterEgos;
  final List<String>? aliases;
  final String? placeOfBirth;
  final String? firstAppearance;
  final String? publisher;
  final String? alignment;

  const Biography({
    this.fullName,
    this.alterEgos,
    this.aliases,
    this.placeOfBirth,
    this.firstAppearance,
    this.publisher,
    this.alignment,
  });

  factory Biography.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v) => v?.toString().trim() ?? '';
    List<String> _list(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) return [v];
      return [];
    }

    return Biography(
      fullName: _s(json['full-name']).isEmpty ? null : _s(json['full-name']),
      alterEgos: _s(json['alter-egos']).isEmpty ? null : _s(json['alter-egos']),
      aliases: _list(json['aliases']),
      placeOfBirth: _s(json['place-of-birth']).isEmpty ? null : _s(json['place-of-birth']),
      firstAppearance: _s(json['first-appearance']).isEmpty ? null : _s(json['first-appearance']),
      publisher: _s(json['publisher']).isEmpty ? null : _s(json['publisher']),
      alignment: _s(json['alignment']).isEmpty ? null : _s(json['alignment']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full-name': fullName,
        if (alterEgos != null) 'alter-egos': alterEgos,
        if (aliases != null && aliases!.isNotEmpty) 'aliases': aliases,
        if (placeOfBirth != null) 'place-of-birth': placeOfBirth,
        if (firstAppearance != null) 'first-appearance': firstAppearance,
        if (publisher != null) 'publisher': publisher,
        if (alignment != null) 'alignment': alignment,
      };

  /// 🔙 Bakåtkompatibilitet: gör att tester som använder `biography['full-name']`
  /// eller `biography['alignment']` fungerar.
  dynamic operator [](String key) {
    switch (key) {
      case 'full-name':
        return fullName;
      case 'alter-egos':
        return alterEgos;
      case 'aliases':
        return aliases;
      case 'place-of-birth':
        return placeOfBirth;
      case 'first-appearance':
        return firstAppearance;
      case 'publisher':
        return publisher;
      case 'alignment':
        return alignment;
      default:
        return null;
    }
  }
}