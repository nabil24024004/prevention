import 'package:flutter_test/flutter_test.dart';
import 'package:prevention/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PreventionApp(isFirstLaunch: true)));
    expect(find.text('PREVENTION'), findsOneWidget);
  });
}
