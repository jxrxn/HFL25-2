# Miniräknare

En miniräknare byggd i **Flutter** — med live-uträkning, mörkt/ljust läge, tusentalsavgränsning, korrekt procentlogik och korrekta decimaler (ingen flyttalsavrundning).

---

## Funktioner

### 🔢 Exakt beräkning med `Decimal`
Räknaren använder **Decimal** i stället för `double`, vilket eliminerar klassiska flyttalsfel  
som `999 999 999.2 → 999 999 999.200000047684`.

Det betyder:
- 100% stabila resultat  
- inga dolda avrundningar  
- exakt procenthantering  
- konsekvent live-uträkning

---

### Live-uträkning
Resultatet uppdateras direkt medan du skriver.  
Exempel:  
`20 + 3 × 2` → visar **26** direkt, även innan du tryckt `=`.

---

### Beräkningshistorik
Den övre remsan visar alltid aktuellt uttryck:
- Visar siffror och operatorer så fort de skrivs  
- Scrollbar i sidled och rullas automatiskt till höger för att visa senaste delen  
- Visar även kompletta uttryck efter `=`:  
  `20 + 3 × 2 = 26`

---

### Procentlogik (korrekt matematiskt beteende)
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

### Rensa & redigera
-	Kort tryck på C: backspace
-	Långt tryck på C: allt rensas (AC)
-	Decimaltecken visas som komma i remsa och resultat

---

### Kopiera resultat

Tryck på stora talet för att kopiera till urklipp.

---

### Mörkt & ljust tema

Automatiskt efter systemtema, eller manuellt via AppBar-knappen.

---

### Begränsningar (för stabilitet)

Räknaren har säkra gränser inspirerade av iOS och Android:
	•	Max heltalsstorlek: 999 999 999 999 999 (15 siffror)
	•	Max totala teckenlängd: 20
	•	För stora tal returnerar Error
	•	Detta garanterar snabb och stabil

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
 │   ├─ calculator_strip_test.dart
 │   └─ calculator_test.dart
 └─ pubspec.yaml
 ```
 ---
 
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


