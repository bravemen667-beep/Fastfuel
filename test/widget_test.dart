import 'package:flutter_test/flutter_test.dart';
import 'package:gofaster_health/main.dart';

void main() {
  testWidgets('GoFaster app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GoFasterApp());
    expect(find.byType(GoFasterApp), findsOneWidget);
  });
}
