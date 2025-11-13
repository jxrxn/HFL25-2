# Miniräknare

En miniräknare byggd i **Flutter** — med live-uträkning, ljust/mörkt-läge, tusentalsavgränsning och intelligent hantering av procent, operatorer och decimaler.

---

## Funktioner

- **Live-uträkning:** resultatet uppdateras direkt medan du skriver.  
- **Remsa:** den aktuella uträkningen visas i en remsa ovanför resultatet.  
- **Långt tryck på `C`:** nollställer allt (`AC`).  
- **Kort tryck på `C`:** raderar senaste tecken.  
- **Tusentalsavgränsning:** stora tal visas som `1 234 567`.  
- **Kopiera resultat:** klicka på resultatet för att kopiera talet till urklipp.  
- **Dark / Light mode** enligt systemtema eller manuellt via AppBar-knappen.
- **Procentuträkning:**
```text
| Uträkning        | Tolkas som                | Resultat |  
|------------------|---------------------------|----------|  
| 50 + 10 %        | 50 + (10% av 50)          | 55       |  
| 50 - 10 %        | 50 - (10% av 50)          | 45       |  
| 100 × 10 %       | 100 × 0.10                | 10       |  
| 100 ÷ 10 %       | 100 ÷ 0.10                | 1000     |  
| 10 %             | 10 ÷ 100                  | 0.1      |  
```

---

## Live-uträkning

När du matar in ett uttryck, visas resultatet direkt i huvuddisplayen medan du skriver.
- Skriver du: `20 + 3 × 2` så visas 26 redan innan du tryckt =.
- Remsan visar alltid det uttryck du bygger upp.
- Efter = sparas hela uttrycket: `20 + 3 × 2 = 26`
- Om du räknar vidare från resultatet så fortsätter remsan korrekt, t.ex.:
`26 + 4`

---  

## Begränsningar

Miniräknaren följer samma säkerhetsgränser som iOS och Android för att undvika fel i flyttalsberäkningar:  
- Max säkert heltal: 999 999 999 999 999 (15 siffror)  
- Max total längd: 20 tecken inkl. decimaler  
- Resultat som överskrider det visas inte, utan triggar felhantering.  
Det gör räknaren stabil även vid stora tal.

---

## Struktur

```text
v03f/
 ├─ lib/
 │   ├─ main.dart
 │   ├─ calculator_screen.dart
 │   ├─ calc_button.dart
 │   ├─ logic/
 │   │   └─ calculator_engine.dart
 │   └─ ui/
 │       ├─ display_widget.dart
 │       └─ button_grid.dart
 ├─ test/
 │   └─ calculator_live_test.dart
 │   └─ calculator_test.dart
 └─ pubspec.yaml
 ```

## Installation

1.	Klona projektet

```bash
git clone https://github.com/jxrxn/HFL25-2.git
cd HFL25-2/v03f
```

2.	Installera beroenden

```bash
flutter pub get
```

3.	Kör appen

```bash
flutter run
```

4.	Kör tester

```bash
flutter test
```


