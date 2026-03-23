import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/admin_theme.dart';
import '../../analytics/analytics_provider.dart';
import '../../analytics/analytics_models.dart';
import '../../widgets/admin_scaffold.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnterpriseAnalyticsProvider>();

    return AdminScaffold(
      title: 'Enterprise Analytics',
      currentRoute: '/dashboard/analytics',
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('Error: ${provider.error}'))
              : _AnalyticsDashboard(data: provider.data!),
    );
  }
}

class _AnalyticsDashboard extends StatelessWidget {
  final AnalyticsDashboardData data;
  const _AnalyticsDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Today's Overview
          _SectionHeader(title: "Today's Overview"),
          const SizedBox(height: 12),
          _TodayOverviewGrid(stats: data.today, isMobile: isMobile),
          
          const SizedBox(height: 24),
          
          // Section 9: Alert System
          if (data.alerts.isNotEmpty) ...[
            _SectionHeader(title: "System Alerts"),
            const SizedBox(height: 12),
            ...data.alerts.map((a) => _AlertCard(alert: a)),
            const SizedBox(height: 24),
          ],

          // Charts Row/Column 1
          if (isMobile) ...[
            _HourlyTrafficCard(data: data.hourlyTraffic),
            const SizedBox(height: 16),
            _BranchPerformanceCard(data: data.branchPerformance),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _HourlyTrafficCard(data: data.hourlyTraffic)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _BranchPerformanceCard(data: data.branchPerformance)),
              ],
            ),
          
          const SizedBox(height: 16),

          // Charts Row/Column 2
          if (isMobile) ...[
            _ServicePopularityCard(data: data.servicePopularity),
            const SizedBox(height: 16),
            _CounterPerformanceCard(data: data.counterPerformance),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ServicePopularityCard(data: data.servicePopularity)),
                const SizedBox(width: 16),
                Expanded(child: _CounterPerformanceCard(data: data.counterPerformance)),
              ],
            ),

          const SizedBox(height: 16),

          // Weekly & Wait Time
          if (isMobile) ...[
            _WeeklyTrafficCard(data: data.weeklyTraffic),
            const SizedBox(height: 16),
            _WaitTimeAnalysisCard(stats: data.waitTimeAnalysis),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _WeeklyTrafficCard(data: data.weeklyTraffic)),
                const SizedBox(width: 16),
                Expanded(child: _WaitTimeAnalysisCard(stats: data.waitTimeAnalysis)),
              ],
            ),

          const SizedBox(height: 16),

          // Queue Load & Predictive
          if (isMobile) ...[
            _QueueLoadCard(stats: data.queueLoad),
            const SizedBox(height: 16),
            _PredictiveCard(data: data.predictive),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _QueueLoadCard(stats: data.queueLoad)),
                const SizedBox(width: 16),
                Expanded(child: _PredictiveCard(data: data.predictive)),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: AdminTheme.primary));
  }
}

class _TodayOverviewGrid extends StatelessWidget {
  final TodayStats stats;
  final bool isMobile;
  const _TodayOverviewGrid({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 6,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.1 : 1.2,
      children: [
        _StatCard(label: 'Total', value: '${stats.total}', icon: Icons.token_outlined, color: AdminTheme.primary),
        _StatCard(label: 'Completed', value: '${stats.completed}', icon: Icons.check_circle_outline, color: AdminTheme.success),
        _StatCard(label: 'Pending', value: '${stats.pending}', icon: Icons.hourglass_top, color: AdminTheme.warning),
        _StatCard(label: 'Skipped', value: '${stats.skipped}', icon: Icons.skip_next_outlined, color: AdminTheme.danger),
        _StatCard(label: 'Avg Wait', value: '${stats.avgWaitTime.toStringAsFixed(1)}m', icon: Icons.timer_outlined, color: AdminTheme.accent),
        _StatCard(label: 'Active Counters', value: '${stats.activeCounters}', icon: Icons.storefront, color: Colors.blueGrey),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AnalyticsAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert.severity == AlertSeverity.critical ? AdminTheme.danger : AdminTheme.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(alert.severity == AlertSeverity.critical ? Icons.error_outline : Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Text(alert.message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// Chart Widgets (implemented in next chunk)
class _HourlyTrafficCard extends StatelessWidget {
  final List<HourlyData> data;
  const _HourlyTrafficCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Hourly Traffic',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, 
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Text('${data[index].hour}h', style: const TextStyle(fontSize: 10));
                }
              )),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data.map((e) => FlSpot(e.hour.toDouble(), e.count.toDouble())).toList(),
                isCurved: true,
                color: AdminTheme.accent,
                barWidth: 3,
                belowBarData: BarAreaData(show: true, color: AdminTheme.accent.withAlpha(30)),
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchPerformanceCard extends StatelessWidget {
  final List<BranchStats> data;
  const _BranchPerformanceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Branch Performance',
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.tokenCount.toDouble(), color: AdminTheme.primary, width: 16, borderRadius: BorderRadius.circular(4))])).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, 
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Text(data[index].branchName.split(' ').last, style: const TextStyle(fontSize: 9));
                }
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
          ),
        ),
      ),
    );
  }
}

class _CounterPerformanceCard extends StatelessWidget {
  final List<CounterStats> data;
  const _CounterPerformanceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Counter Performance',
      child: Column(
        children: data.take(5).map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(c.counterName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              Expanded(
                child: LinearProgressIndicator(
                  value: c.tokensServed / 100, // Normalized for visual
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: AdminTheme.accent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text('${c.tokensServed} tkn', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _ServicePopularityCard extends StatelessWidget {
  final List<ServiceStats> data;
  const _ServicePopularityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Service Popularity',
      child: SizedBox(
        height: 250,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: data.isEmpty 
                ? [PieChartSectionData(value: 1, title: 'No Data', color: Colors.grey.withAlpha(50), radius: 50)]
                : data.take(5).toList().asMap().entries.map((e) => PieChartSectionData(
                  value: e.value.count.toDouble(),
                  title: '${e.value.count}',
                  radius: 50,
                  color: [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red][e.key % 5],
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                )).toList(),
          ),
        ),
      ),
    );
  }
}

class _WaitTimeAnalysisCard extends StatelessWidget {
  final WaitTimeStats stats;
  const _WaitTimeAnalysisCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Wait Time Analysis',
      child: Column(
        children: [
          _WaitMetric(label: 'Avg Wait', value: '${stats.avgWaitMinutes.toStringAsFixed(1)}m', color: AdminTheme.accent),
          const Divider(),
          _WaitMetric(label: 'Max Wait', value: '${stats.maxWaitMinutes}m', color: AdminTheme.danger),
          const Divider(),
          _WaitMetric(label: 'Min Wait', value: '${stats.minWaitMinutes}m', color: AdminTheme.success),
        ],
      ),
    );
  }
}

class _WaitMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _WaitMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrafficCard extends StatelessWidget {
  final List<WeeklyData> data;
  const _WeeklyTrafficCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Weekly Traffic',
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.count.toDouble(), color: AdminTheme.accent, width: 20, borderRadius: BorderRadius.circular(6))])).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, 
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Text(data[index].date.substring(0, 3), style: const TextStyle(fontSize: 10));
                }
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
          ),
        ),
      ),
    );
  }
}

class _QueueLoadCard extends StatelessWidget {
  final QueueLoadStats stats;
  const _QueueLoadCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Queue Load',
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: AdminTheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${stats.totalWaiting}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const Text('Total Waiting', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _QueueStatItem(
            label: 'Longest Queue', 
            value: '${stats.longestQueueCount}', 
            subValue: 'Counter: ${stats.longestQueueCounter.length > 4 ? stats.longestQueueCounter.substring(0, 4) : stats.longestQueueCounter}', 
            color: AdminTheme.danger
          ),
          const SizedBox(height: 12),
          _QueueStatItem(
            label: 'Shortest Queue', 
            value: '${stats.shortestQueueCount}', 
            subValue: 'Counter: ${stats.shortestQueueCounter.length > 4 ? stats.shortestQueueCounter.substring(0, 4) : stats.shortestQueueCounter}', 
            color: AdminTheme.success
          ),
        ],
      ),
    );
  }
}

class _QueueStatItem extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;
  const _QueueStatItem({required this.label, required this.value, required this.subValue, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(subValue, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ]),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _PredictiveCard extends StatelessWidget {
  final PredictiveData data;
  const _PredictiveCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Smart Insights',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: AdminTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            const Text('Tomorrow Prediction', style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text('${data.expectedTokensTomorrow}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            const Text('Estimated Tokens', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text('Peak Hour: ${data.peakHour} AM', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DashboardCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminTheme.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
