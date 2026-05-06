import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campusconnect/widgets/app_search_field.dart';

void main() {
  group('AppSearchField Widget Tests', () {
    testWidgets('AppSearchField renders with placeholder text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              hintText: 'Search items',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search items'), findsOneWidget);
    });

    testWidgets('AppSearchField calls onChanged when text is entered', (WidgetTester tester) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              hintText: 'Search',
              onChanged: (value) {
                searchQuery = value;
              },
            ),
          ),
        ),
      );

      final Finder textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'flutter');
      await tester.pumpAndSettle();

      expect(searchQuery, 'flutter');
    });

    testWidgets('AppSearchField has search icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              hintText: 'Search',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('AppSearchField displays multiple input changes correctly', (WidgetTester tester) async {
      final List<String> inputHistory = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              hintText: 'Search items',
              onChanged: (value) {
                inputHistory.add(value);
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'market');
      await tester.pumpAndSettle();
      expect(inputHistory.last, 'market');

      await tester.enterText(find.byType(TextField), 'marketplace');
      await tester.pumpAndSettle();
      expect(inputHistory.last, 'marketplace');
    });
  });
}
