class Work {
  final String? occupation;
  final String? base;

  const Work({
    this.occupation,
    this.base,
  });

  factory Work.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v) => v?.toString().trim() ?? '';

    final occupation = _s(json['occupation']);
    final base = _s(json['base']);

    return Work(
      occupation: occupation.isEmpty ? null : occupation,
      base: base.isEmpty ? null : base,
    );
  }

  Map<String, dynamic> toJson() => {
        if (occupation != null) 'occupation': occupation,
        if (base != null) 'base': base,
      };

  /// 🔙 Bakåtkompatibilitet — stöd för `work['occupation']`
  /// i äldre tester eller JSON-strukturer.
  dynamic operator [](String key) {
    switch (key) {
      case 'occupation':
        return occupation;
      case 'base':
        return base;
      default:
        return null;
    }
  }
}