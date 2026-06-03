import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminKpiChartsScreen extends StatefulWidget {
  const AdminKpiChartsScreen({super.key});

  @override
  State<AdminKpiChartsScreen> createState() => _AdminKpiChartsScreenState();
}

class _AdminKpiChartsScreenState extends State<AdminKpiChartsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadWeeklyKpi();
    });
  }

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('KPI & Statistik',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            onPressed: () => admin.loadWeeklyKpi(),
          ),
        ],
      ),
      body: admin.isLoadingKpi
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : admin.weeklyKpi == null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: admin.loadWeeklyKpi,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle('Tingkat Kehadiran Mingguan (%)'),
                      const SizedBox(height: 12),
                      _buildAttendanceRateChart(admin),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Tren Keterlambatan (orang)'),
                      const SizedBox(height: 12),
                      _buildLateTrendChart(admin),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Distribusi Jam Absen Masuk'),
                      const SizedBox(height: 12),
                      _buildHourlyDistributionChart(admin),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded,
                color: AppColors.textSecondary, size: 52),
            const SizedBox(height: 12),
            const Text('Belum ada data KPI',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.read<AdminProvider>().loadWeeklyKpi(),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15),
      );

  // ── Weekly Attendance Rate (Line Chart) ─────────────────────────
  Widget _buildAttendanceRateChart(AdminProvider admin) {
    final kpi = admin.weeklyKpi!;
    final spots = List.generate(
      7,
      (i) => FlSpot(i.toDouble(), kpi.attendanceRates[i]),
    );

    return _chartCard(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.textMuted.withAlpha(30),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 25,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= 7) return const SizedBox();
                    return Text(_dayLabels[i],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11));
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.secondary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.secondary,
                    strokeWidth: 2,
                    strokeColor: AppColors.primaryDark,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.secondary.withAlpha(60),
                      AppColors.secondary.withAlpha(5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Late Trend (Bar Chart) ───────────────────────────────────────
  Widget _buildLateTrendChart(AdminProvider admin) {
    final kpi = admin.weeklyKpi!;
    final maxLate =
        kpi.lateTrend.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return _chartCard(
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxLate + 2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxLate / 4).clamp(1, double.infinity),
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.textMuted.withAlpha(30),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= 7) return const SizedBox();
                    return Text(_dayLabels[i],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11));
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(
              7,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: kpi.lateTrend[i],
                    color: AppColors.warning,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxLate + 2,
                      color: AppColors.warning.withAlpha(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hourly Distribution (Bar Chart) ─────────────────────────────
  Widget _buildHourlyDistributionChart(AdminProvider admin) {
    final kpi = admin.weeklyKpi!;

    // Only show work hours 6-18
    final hourRange = List.generate(13, (i) => i + 6);
    final maxCount = hourRange
        .map((h) => kpi.hourlyDistribution[h] ?? 0)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity)
        .toDouble();

    return _chartCard(
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            maxY: maxCount + 2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.textMuted.withAlpha(30),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final h = v.toInt() + 6;
                    if (v.toInt() % 2 != 0) return const SizedBox();
                    return Text('${h.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 9));
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: hourRange.asMap().entries.map((entry) {
              final i = entry.key;
              final h = entry.value;
              final count = (kpi.hourlyDistribution[h] ?? 0).toDouble();
              // Color peaks
              Color barColor;
              if (h < 8) {
                barColor = AppColors.success;
              } else if (h <= 9) {
                barColor = AppColors.warning;
              } else {
                barColor = AppColors.error;
              }
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: count,
                    color: barColor,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _chartCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withAlpha(15)),
        ),
        child: child,
      );
}
