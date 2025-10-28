class Appearance {
  final String? gender;
  final String? race;
  final List<String>? height; // ex: ["5'10", "178 cm"]
  final List<String>? weight; // ex: ["170 lb", "77 kg"]
  final String? eyeColor;
  final String? hairColor;

  const Appearance({
    this.gender,
    this.race,
    this.height,
    this.weight,
    this.eyeColor,
    this.hairColor,
  });

  factory Appearance.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString().trim() ?? '';
    List<String> list(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) return [v];
      return [];
    }

    final gender = s(json['gender']);
    final race = s(json['race']);
    final eye = s(json['eye-color']);
    final hair = s(json['hair-color']);
    final height = list(json['height']);
    final weight = list(json['weight']);

    return Appearance(
      gender: gender.isEmpty ? null : gender,
      race: race.isEmpty ? null : race,
      eyeColor: eye.isEmpty ? null : eye,
      hairColor: hair.isEmpty ? null : hair,
      height: height.isEmpty ? null : height,
      weight: weight.isEmpty ? null : weight,
    );
  }

  Map<String, dynamic> toJson() => {
        if (gender != null) 'gender': gender,
        if (race != null) 'race': race,
        if (height != null && height!.isNotEmpty) 'height': height,
        if (weight != null && weight!.isNotEmpty) 'weight': weight,
        if (eyeColor != null) 'eye-color': eyeColor,
        if (hairColor != null) 'hair-color': hairColor,
      };

  /// 🔙 Bakåtkompatibilitet för tester/äldre kod:
  /// gör att `appearance['gender']` m.m. fungerar.
  dynamic operator [](String key) {
    switch (key) {
      case 'gender':
        return gender;
      case 'race':
        return race;
      case 'height':
        return height;
      case 'weight':
        return weight;
      case 'eye-color':
        return eyeColor;
      case 'hair-color':
        return hairColor;
      default:
        return null;
    }
  }
}