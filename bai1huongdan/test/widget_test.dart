import 'package:flutter_test/flutter_test.dart';
import 'package:bai1huongdan/main.dart';

void main() {
  testWidgets('Main App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.text('Welcome to the Main App!'), findsOneWidget);
  });
}
