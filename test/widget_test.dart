import 'package:flutter_test/flutter_test.dart';

import 'package:mockup/main.dart';

void main() {
  testWidgets('shows localized login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to Pasaty!'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
