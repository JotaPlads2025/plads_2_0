import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../theme/app_theme.dart';

class RevenueChart extends StatefulWidget {
  final List<double> monthlyRevenue; // Last 6 months
  final bool isDark;

  const RevenueChart({super.key, required this.monthlyRevenue, required this.isDark});

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
        child: LineChart(
          _mainData(),
        ),
      ),
    );
  }

  LineChartData _mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 100000, // Adjust relative to data
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: widget.isDark ? Colors.white10 : Colors.black12,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30, // reserved size for bottom titles
            getTitlesWidget: bottomTitleWidgets,
            interval: 1,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y axis for cleaner look, or verify
        // Ideally we show compact numbers (10k, 20k)
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (widget.monthlyRevenue.length - 1).toDouble(),
      minY: 0,
      maxY: (widget.monthlyRevenue.reduce((a, b) => a > b ? a : b) * 1.2), // Max + buffer
      lineBarsData: [
        LineChartBarData(
          spots: widget.monthlyRevenue.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value);
          }).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              AppColors.neonPurple,
              AppColors.neonBlue,
            ],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.neonPurple.withOpacity(0.3),
                AppColors.neonBlue.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              return LineTooltipItem(
                '\$${flSpot.y.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Colors.grey,
    );
    
    // Simulate last X months labels
    // In real app, pass labels list
    final now = DateTime.now();
    final date = DateTime(now.year, now.month - (widget.monthlyRevenue.length - 1 - value.toInt()));
    final monthName = _monthName(date.month);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(monthName, style: style),
    );
  }

  String _monthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }
}
