import 'package:flutter_test/flutter_test.dart';
import 'package:gongter/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GongterApp());
  });
}
