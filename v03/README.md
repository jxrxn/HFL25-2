# HeroDex 3000

En Dart-app du kan använda i terminalen. Skapa, visa, sök och ta bort hjältar.  
Sparas automatiskt i JSON-format.

---

## ⚙️ Funktioner
1. Lägg till hjälte (namn, styrka, specialkraft, kön, ursprung, alignment)
2. Visa hjältar (sorterade efter styrka)
3. Sök efter hjältar
4. Ta bort hjälte (via nummer eller namn)
5. Automatisk spara/ladda från `heroes.json`

  •	 Singleton (HeroDataManager.instance) säkerställer en enda global instans.  
  •	 Abstrakt interface (HeroDataManaging) gör det lätt att byta ut lagring (t.ex. fil, API, moln).  
  •  JSON-persistens via dart:io och dart:convert.  
  •	 Färgade meddelanden för info, felmeddelanden och varningar.  

---

## 💡 Gör såhär

### Gå till din GitHub-mapp (eller där du vill ha projektet)
```bash
cd ~/Documents/GitHub
```

### Klona projektet (skapar mappen HFL25-2)
```bash
git clone https://github.com/jxrxn/HFL25-2.git
```

### Gå in i version 02
```bash
cd HFL25-2/v03
```

### Hämta paket
```bash
dart pub get
```

### Kör programmet
```bash
dart run bin/herodex.dart
```


## 🧪 Olika lägen

Du kan nu starta HeroDex i tre olika lägen:

| Läge | Kommando | Beskrivning |
|------|-----------|-------------|
| **Standardläge** | `dart run bin/herodex.dart` | Läser och sparar hjältar i `heroes.json` |
| **Mockläge** | `dart run bin/herodex.dart --mock` | Startar med tre filosofer (Platon, Aristoteles, Epiktetos) för test |
| **Egen datafil** | `dart run bin/herodex.dart --data=custom.json` | Använder en specifik JSON-fil för lagring |


##  ✅ Tester

Projektet innehåller enhetstester i test/:  
	•	hero_data_manager_test.dart  
	•	hero_model_test.dart  
	•	class_abstract_test.dart  

Kör alla tester:
```bash
dart test
```
