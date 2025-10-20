class ExampleManager {
  static final ExampleManager _instance = ExampleManager._internal();

  factory ExampleManager() {
    print('➡️  factory called — returning SAME instance');
    return _instance;
  }

  ExampleManager._internal() {
    print('🧱 internal constructor called ONCE when instance is first created');
  }

  int counter = 0;
}

void main() {
  final a = ExampleManager();
  final b = ExampleManager();

  a.counter++;
  print('A counter = ${a.counter}');
  print('B counter = ${b.counter}');
  print('a == b ? ${identical(a, b)}');
}
