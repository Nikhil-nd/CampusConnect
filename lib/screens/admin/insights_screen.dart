import 'package:flutter/material.dart';

import '../../widgets/insights/reports_trend_chart.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Insights')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const <Widget>[
            Text('Reports (last 7 days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            ReportsTrendChart(),
            SizedBox(height: 18),
            Text(
              'What insight does this give the user?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'This chart shows the number of spam/reports per day over the last 7 days. It highlights whether reports are rising, falling, or stable — a quick signal for moderators to investigate increased activity or to confirm that moderation actions reduced issues.',
            ),
          ],
        ),
      ),
    );
  }
}
