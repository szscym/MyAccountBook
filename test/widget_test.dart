import 'package:flutter_test/flutter_test.dart';

import 'package:money_minder/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MoneyMinderApp());
    // Verify the app loads with the bottom navigation bar
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('流水'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
  });
}
