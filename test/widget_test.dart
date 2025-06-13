import 'package:flutter_test/flutter_test.dart';
import 'package:urmt/main.dart';

void main() {
  testWidgets('HomePage has correct UI elements', (WidgetTester tester) async {
    // 构建我们的 app 并触发一帧
    await tester.pumpWidget(MyApp());

    // 检查顶部三个按钮
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Summon'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // 检查主内容区文本
    expect(find.text('Main Content Area'), findsOneWidget);
  });
}