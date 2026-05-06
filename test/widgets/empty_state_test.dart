import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campusconnect/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('EmptyState renders with icon, title, and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No items found',
              subtitle: 'Try adding your first item.',
              icon: Icons.inbox_outlined,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Try adding your first item.'), findsOneWidget);
    });

    testWidgets('EmptyState renders action button when provided', (WidgetTester tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No listings',
              subtitle: 'Create your first listing.',
              icon: Icons.store_outlined,
              actionLabel: 'Create',
              onAction: () {
                actionTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Create'), findsOneWidget);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });

    testWidgets('EmptyState does not render action button when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              subtitle: 'No data',
              icon: Icons.info_outline,
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('EmptyState action button triggers onAction callback', (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Retry test',
              subtitle: 'Action button test',
              icon: Icons.refresh_outlined,
              actionLabel: 'Retry',
              onAction: () {
                callCount++;
              },
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(callCount, equals(1));

      // Tap again to verify it can be tapped multiple times
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(callCount, equals(2));
    });
  });
}
