// lib/models/hero_model.dart

class HeroModel {
  final String id;
  final String name;

  /// Valfria undermappar (kan saknas i JSON)
  final Map<String, dynamic>? powerstats;
  final Map<String, dynamic>? biography;
  final Map<String, dynamic>? appearance;
  final Map<String, dynamic>? work;
  final Map<String, dynamic>? connections;
  final Map<String, dynamic>? image;

  HeroModel({
    required this.id,
    required this.name,
    this.powerstats,
    this.biography,
    this.appearance,
    this.work,
    this.connections,
    this.image,
  });

  /// Liten hjälpare: gör om dynamiskt värde till `Map<String, dynamic>` om möjligt.
  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// Bygger modellen robust från JSON – tål t.ex. int id och saknade fält.
  factory HeroModel.fromJson(Map<String, dynamic> json) {
    return HeroModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Okänd hjälte',
      powerstats: _asMap(json['powerstats']),
      biography: _asMap(json['biography']),
      appearance: _asMap(json['appearance']),
      work: _asMap(json['work']),
      connections: _asMap(json['connections']),
      image: _asMap(json['image']),
    );
  }

  /// JSON-serialisering – hoppar över null-fält.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (powerstats != null) 'powerstats': powerstats,
      if (biography != null) 'biography': biography,
      if (appearance != null) 'appearance': appearance,
      if (work != null) 'work': work,
      if (connections != null) 'connections': connections,
      if (image != null) 'image': image,
    };
  }

  // ===== Bekväma getters =====

  /// Tolkning av styrka som int (tål int/str/null i källan).
  int get strengthAsInt => int.tryParse('${powerstats?['strength'] ?? 0}') ?? 0;

  /// Säker bild-URL (bra inför ev. ASCII-visning).
  String? get imageUrl {
    final u = image?['url'];
    return (u is String && u.trim().isNotEmpty) ? u : null;
  }

  /// Alias-namn (kan vara en lista i biography).
  List<String> get aliases {
    final raw = biography?['aliases'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return const [];
  }

  /// Försöker hitta en höjd i cm i appearance["height"] (t.ex. ["6'2","188 cm"]).
  int? get heightCm {
    final raw = appearance?['height'];
    if (raw is List && raw.isNotEmpty) {
      final cm = raw.firstWhere(
        (e) => e is String && e.contains('cm'),
        orElse: () => null,
      );
      if (cm is String) {
        final m = RegExp(r'(\d+)').firstMatch(cm);
        if (m != null) return int.tryParse(m.group(1)!);
      }
    }
    return null;
    }

  /// Försöker hitta vikt i kg i appearance["weight"] (t.ex. ["210 lb","95 kg"]).
  int? get weightKg {
    final raw = appearance?['weight'];
    if (raw is List && raw.isNotEmpty) {
      final kg = raw.firstWhere(
        (e) => e is String && e.contains('kg'),
        orElse: () => null,
      );
      if (kg is String) {
        final m = RegExp(r'(\d+)').firstMatch(kg);
        if (m != null) return int.tryParse(m.group(1)!);
      }
    }
    return null;
  }

  // ===== Utskrifter =====

  /// Kompakt representation.
  String toShortString() {
    final fullName = biography?['full-name'] ?? 'Okänt';
    final gender = appearance?['gender'] ?? 'Okänt';
    final strength = powerstats?['strength'] ?? '?';
    return '$name ($fullName) | styrka: $strength | kön: $gender';
  }

  /// Mer informativ visning (det du vill se i listan).
  String toPrettyString() {
  final fullName = biography?['full-name'] ?? 'Okänt';
  final gender = appearance?['gender'] ?? 'Okänt';
  final race = appearance?['race'] ?? 'Okänt';
  final strength = powerstats?['strength'] ?? '?';
  final alignment = biography?['alignment'] ?? 'okänd';
  final special = work?['occupation'] ?? 'ingen';
  final h = heightCm != null ? '$heightCm cm' : '';
  final w = weightKg != null ? '$weightKg kg' : '';
  final hw = [h, w].where((x) => x.isNotEmpty).join(' / ');

  final aliasPart = aliases.isNotEmpty
      ? 'alias: ${aliases.take(2).join(", ")}'
      : '';

  final imagePart = imageUrl != null
      ? 'bild: ${imageUrl!.split("/").last}'
      : '';

  final extras = [hw, aliasPart, imagePart]
      .where((x) => x.isNotEmpty)
      .join(' | ');

  final mainInfo =
    '$name ($fullName) | styrka: $strength | kön: $gender | '
    'ursprung: $race | alignment: $alignment | special: $special';

  return extras.isNotEmpty ? '$mainInfo | $extras' : mainInfo;
}

  @override
  String toString() => toPrettyString();

  // ===== Frivilligt: immutabel uppdatering =====
  HeroModel copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? powerstats,
    Map<String, dynamic>? biography,
    Map<String, dynamic>? appearance,
    Map<String, dynamic>? work,
    Map<String, dynamic>? connections,
    Map<String, dynamic>? image,
  }) {
    return HeroModel(
      id: id ?? this.id,
      name: name ?? this.name,
      powerstats: powerstats ?? this.powerstats,
      biography: biography ?? this.biography,
      appearance: appearance ?? this.appearance,
      work: work ?? this.work,
      connections: connections ?? this.connections,
      image: image ?? this.image,
    );
  }
}