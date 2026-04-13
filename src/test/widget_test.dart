import 'package:flutter_test/flutter_test.dart';

import 'package:supermarket_stock_take_desktop/main.dart';

void main() {
  testWidgets('home shows API base hint', (WidgetTester tester) async {
    await tester.pumpWidget(const StockTakeApp());
    expect(find.textContaining('localhost:8080'), findsOneWidget);
  });
}
