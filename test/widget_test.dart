import 'package:flutter_test/flutter_test.dart';
import 'package:ortho_quest/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OrthoQuestApp());
    expect(find.text("OrthoQuest"), findsOneWidget); // AppBar title
  });
}
