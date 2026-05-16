import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a basic widget tree', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Startups India'),
        ),
      ),
    );

    expect(find.text('Startups India'), findsOneWidget);
  });
}
