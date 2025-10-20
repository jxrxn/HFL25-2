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
  •	 Varje hjälte får ett globalt unikt ID (UUID v4) genererat med paketet uuid.  

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


## 🔑 SuperHero API – sök hjältar online

För att HeroDex 3000 ska kunna söka hjältar online använder den **SuperHero API**.  
Du behöver en personlig **API-token** som identifierar din inloggning mot tjänsten.

### 1️⃣ Skaffa din token
1. Gå till [https://www.superheroapi.com/](https://www.superheroapi.com/)
2. Logga in med ditt GitHub-konto
3. Du får automatiskt en **access token** (en rad med 32 hexadecimala siffror).  
   Kopiera den.

### 2️⃣ Skapa din `.env`-fil
I mappen `v04/` (samma där `bin/` och `lib/` finns) – skapa en ny fil som heter **`.env`**  
och klistra in följande rad:

```bash
SUPERHERO_API_TOKEN=din_token_här
```
🔒 Viktigt: .env finns med i .gitignore så den kommer inte att laddas upp till GitHub.
Dela aldrig din riktiga token offentligt.

✅ Testa att din token fungerar
Kör följande kommando i terminalen:
```bash
dart run bin/check_env.dart
```
Om allt är korrekt ser du något liknande:
```bash
TOKEN_STATUS=present
TOKEN_MASKED=7ad•••6c1
TOKEN_LENGTH=32
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
	•	hero_data_manager_mock_test.dart  
	•	hero_model_test.dart  
	•	class_abstract_test.dart  

Kör alla tester:
```bash
dart test
```
