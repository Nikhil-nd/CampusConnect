import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report_model.dart';
import '../../services/firestore_service.dart';

class ReportsTrendChart extends StatelessWidget {
  const ReportsTrendChart({super.key});

  List<DateTime> _lastNDays(int n) {
    final DateTime now = DateTime.now();
    return List<DateTime>.generate(n, (int i) {
      final DateTime day = DateTime(now.year, now.month, now.day).subtract(Duration(days: n - 1 - i));
      return day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();
    final List<DateTime> days = _lastNDays(7);

    return StreamBuilder<List<ReportModel>>(
      stream: firestore.watchReports(unresolvedOnly: false),
      builder: (BuildContext context, AsyncSnapshot<List<ReportModel>> snap) {
        if (snap.hasError) {
          return SizedBox(
            height: 180,
            child: Center(child: Text('Could not load insights: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }

        final List<ReportModel> reports = snap.data!;

        // Count per day
        final Map<String, int> counts = <String, int>{};
        for (final DateTime d in days) {
          counts['${d.year}-${d.month}-${d.day}'] = 0;
        }

        for (final ReportModel r in reports) {
          final DateTime created = r.createdAt;
          final String key = '${created.year}-${created.month}-${created.day}';
          if (counts.containsKey(key)) {
            counts[key] = counts[key]! + 1;
          }
        }

        final List<int> values = counts.keys.map((String k) => counts[k] ?? 0).toList();

        // Insight: compare average of last 3 days vs previous 4
        final int n = values.length;
        final double last3 = (n >= 3) ? (values.sublist(n - 3, n).fold<int>(0, (p, e) => p + e) / 3.0) : 0.0;
        final double prev = (n > 3) ? (values.sublist(0, n - 3).fold<int>(0, (p, e) => p + e) / (n - 3)) : 0.0;

        String insight;
        if (prev == 0 && last3 == 0) {
          insight = 'No reports in the last week.';
        } else if (prev == 0 && last3 > 0) {
          insight = 'Reports started appearing in the last 3 days.';
        } else {
          final double change = ((last3 - prev) / (prev == 0 ? 1 : prev)) * 100.0;
          if (change > 10) {
            insight = 'Reports increasing (${change.toStringAsFixed(0)}% vs prior period). Investigate.';
          } else if (change < -10) {
            insight = 'Reports decreasing (${change.toStringAsFixed(0)}%). Good.';
          } else {
            insight = 'Reports stable (${change.toStringAsFixed(0)}%).';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _BarChartPainter(values, Theme.of(context).colorScheme.primary),
                child: Container(),
              ),
            ),
            const SizedBox(height: 8),
            Text(insight, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: days
                  .map((DateTime d) => Text('${d.month}/${d.day}', style: const TextStyle(color: Colors.black54)))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    const double gap = 6.0;
    final int n = values.length;
    if (n == 0) return;
    final double barWidth = (size.width - (gap * (n + 1))) / n;
    final int maxV = values.isEmpty ? 1 : (values.reduce((a, b) => a > b ? a : b));
    final double scale = maxV == 0 ? 0 : (size.height - 20) / maxV;

    for (int i = 0; i < n; i++) {
      final double left = gap + i * (barWidth + gap);
      final double h = values[i] * scale;
      final Rect r = Rect.fromLTWH(left, size.height - h, barWidth, h);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
