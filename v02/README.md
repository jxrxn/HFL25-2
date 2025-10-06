# HeroDex 3000

En Dart-app du kan använda i terminalen. Skapa, visa, sök och ta bort hjältar.  
Sparas automatiskt i JSON-format.

---

## 🚀 Funktioner
1. 🆕 Lägg till hjälte (namn, styrka, specialkraft, kön, ursprung, alignment)
2. 📜 Visa hjältar (sorterade efter styrka)
3. 🔍 Sök efter hjältar
4. ❌ Ta bort hjälte (via nummer eller namn)
5. 💾 Automatisk spara/ladda från `heroes.json`
- 🎨 Färgade meddelanden för info, felmeddelandeb, varning

---

## 🛠️ Kör det här i terminalen

```bash
git clone https://github.com/jxrxn/HFL25-2.git
cd HFL25-2/v02
dart pub get
dart run bin/herodex.dart
```

💡 Om du får meddelandet “The default interactive shell is now zsh”, skriv bara 
```
exit
```
och kör kommandona igen — det påverkar inte programmet.
