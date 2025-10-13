class HeroModel {
  final String id;
  final String name;

  /// Dessa är frivilliga (kan saknas i JSON)
  final Map<String, dynamic>? powerstats;
  final Map<String, dynamic>? biography;
  final Map<String, dynamic>? appearance;
  final Map<String, dynamic>? work;
  final Map<String, dynamic>? connections;
  final Map<String, dynamic>? image;

  /// Konstruktor
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

  /// Skapa en hjälte från JSON-data
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

  /// Gör om till JSON (för att spara till fil)
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

  /// För debug / utskrift i terminalen
  @override
  String toString() {
    final fullName = biography?['full-name'] ?? 'Okänt';
    final gender = appearance?['gender'] ?? 'Okänt';
    final strength = powerstats?['strength'] ?? '?';
    return '$name ($fullName) | styrka: $strength | kön: $gender';
  }
}
