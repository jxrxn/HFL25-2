// lib/models/hero_model.dart

class HeroModel {
  final String id;
  final String name;

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

  factory HeroModel.fromJson(Map<String, dynamic> json) {
    return HeroModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Okänd hjälte',
      powerstats: (json['powerstats'] as Map?)?.cast<String, dynamic>(),
      biography: (json['biography'] as Map?)?.cast<String, dynamic>(),
      appearance: (json['appearance'] as Map?)?.cast<String, dynamic>(),
      work: (json['work'] as Map?)?.cast<String, dynamic>(),
      connections: (json['connections'] as Map?)?.cast<String, dynamic>(),
      image: (json['image'] as Map?)?.cast<String, dynamic>(),
    );
  }

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

  // Hjälpare: tolka styrka robust (kan vara int/str/null).
  int get strengthAsInt => int.tryParse('${powerstats?['strength'] ?? 0}') ?? 0;

  // Valfri kompakt representation
  String toShortString() {
    final fullName = biography?['full-name'] ?? 'Okänt';
    final gender = appearance?['gender'] ?? 'Okänt';
    final strength = powerstats?['strength'] ?? '?';
    return '$name ($fullName) | styrka: $strength | kön: $gender';
  }

  // Mer informativ visning (det du vill se i listan)
  String toPrettyString() {
    final fullName = biography?['full-name'] ?? 'Okänt';
    final gender = appearance?['gender'] ?? 'Okänt';
    final race = appearance?['race'] ?? 'Okänt';
    final strength = powerstats?['strength'] ?? '?';
    final alignment = biography?['alignment'] ?? 'okänd';
    final special = work?['occupation'] ?? 'ingen';
    return '$name ($fullName) | styrka: $strength | kön: $gender | '
        'ursprung: $race | alignment: $alignment | special: $special';
  }

  @override
  String toString() => toPrettyString();
}
