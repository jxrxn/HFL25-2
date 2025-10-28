import 'dart:convert';

Future <void> main()async {

  Map<String, dynamic> data = {'status': 'Initial Data'};

  print('1. Main-funktion startad. Status: ${data['status']}');

  await fetchData()

      .then((jsonString) {

        print("3. Parsar data");

        Map<String, dynamic> parsedData = jsonDecode(jsonString);

        data = parsedData;

      })

      .catchError((e) {

        print("Ett fel inträffade: $e");

        print({'status': 'error', 'message': e.toString()});

      });

  print('4. Data har bearbetats.');

  print('5. Slutgiltigt resultat: ${data['hero']}');

}

Future<String> fetchData() async {

  print('2. Börjar hämta data...');

  await Future.delayed(Duration(seconds: 1));

  return '{"status": "ok", "hero": "Dr. Strange"}';

}
 