class Powerstats {
  final int strength;
  final int intelligence;
  final int speed;
  final int durability;
  final int power;
  final int combat;

  const Powerstats({
    this.strength = 0,
    this.intelligence = 0,
    this.speed = 0,
    this.durability = 0,
    this.power = 0,
    this.combat = 0,
  });

  factory Powerstats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int clamp01(int n) => n.clamp(0, 100);

    return Powerstats(
      strength:     clamp01(toInt(json['strength'])),
      intelligence: clamp01(toInt(json['intelligence'])),
      speed:        clamp01(toInt(json['speed'])),
      durability:   clamp01(toInt(json['durability'])),
      power:        clamp01(toInt(json['power'])),
      combat:       clamp01(toInt(json['combat'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'intelligence': intelligence,
        'speed': speed,
        'durability': durability,
        'power': power,
        'combat': combat,
      };

  /// 🔙 Bakåtkompatibilitet: gör att tester som använder `powerstats['strength']` fungerar.
  dynamic operator [](String key) {
    switch (key) {
      case 'strength':
        return strength.toString();
      case 'intelligence':
        return intelligence.toString();
      case 'speed':
        return speed.toString();
      case 'durability':
        return durability.toString();
      case 'power':
        return power.toString();
      case 'combat':
        return combat.toString();
      default:
        return null;
    }
  }
}