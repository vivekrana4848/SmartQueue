import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/token_model.dart';
import '../models/queue_model.dart';
import '../models/counter_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import 'analytics_models.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AnalyticsDashboardData> streamFullAnalytics() {
    // We combine multiple streams for a real-time reactive dashboard
    // For simplicity in this enterprise version, we'll fetch once or use a combined stream
    return _db.collection('tokens').snapshots().asyncMap((tokenSnap) async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      final allTokens = tokenSnap.docs.map((d) => TokenModel.fromDoc(d)).toList();
      final todayTokens = allTokens.where((t) => t.createdAt.isAfter(todayStart)).toList();

      // 1. Today Overview
      final countersSnap = await _db.collection('counters').get();
      final counters = countersSnap.docs.map((d) => CounterModel.fromDoc(d)).toList();
      
      final completedToday = todayTokens.where((t) => t.status == TokenStatus.completed).toList();
      final totalWaitTime = completedToday.fold(0, (sum, t) => sum + (t.completedAt?.difference(t.createdAt).inMinutes ?? 0));
      final avgWaitToday = completedToday.isEmpty ? 0.0 : totalWaitTime / completedToday.length;

      final todayStats = TodayStats(
        total: todayTokens.length,
        completed: completedToday.length,
        pending: todayTokens.where((t) => t.status == TokenStatus.waiting || t.status == TokenStatus.serving).length,
        skipped: todayTokens.where((t) => t.status == TokenStatus.skipped).length,
        avgWaitTime: avgWaitToday,
        activeCounters: counters.where((c) => c.isActive).length,
      );

      // 2. Hourly Traffic
      final hourlyMap = <int, int>{};
      for (var t in todayTokens) {
        final hour = t.createdAt.hour;
        hourlyMap[hour] = (hourlyMap[hour] ?? 0) + 1;
      }
      final hourlyTraffic = List.generate(24, (h) => HourlyData(h, hourlyMap[h] ?? 0));

      // 3. Branch Performance
      final branchMap = <String, int>{};
      final branchNames = <String, String>{};
      for (var t in allTokens) {
        branchMap[t.branchId] = (branchMap[t.branchId] ?? 0) + 1;
        branchNames[t.branchId] = t.branchName;
      }
      final branchStats = branchMap.entries.map((e) => BranchStats(e.key, branchNames[e.key] ?? 'Unknown', e.value)).toList();

      // 4. Counter Performance
      final counterMap = <String, int>{};
      final counterServiceTime = <String, int>{};
      final counterNames = <String, String>{};
      for (var t in allTokens.where((t) => t.status == TokenStatus.completed)) {
        counterMap[t.counterId] = (counterMap[t.counterId] ?? 0) + 1;
        counterNames[t.counterId] = t.counterName;
        final serviceTime = t.completedAt?.difference(t.createdAt).inMinutes ?? 0;
        counterServiceTime[t.counterId] = (counterServiceTime[t.counterId] ?? 0) + serviceTime;
      }
      final counterStats = counterMap.entries.map((e) {
        final totalTokens = e.value;
        final totalTime = counterServiceTime[e.key] ?? 0;
        return CounterStats(e.key, counterNames[e.key] ?? 'Unknown', totalTokens, totalTokens == 0 ? 0 : totalTime / totalTokens);
      }).toList();

      // 5. Service Popularity
      final serviceMap = <String, int>{};
      final serviceNames = <String, String>{};
      for (var t in allTokens) {
        serviceMap[t.serviceId] = (serviceMap[t.serviceId] ?? 0) + 1;
        serviceNames[t.serviceId] = t.serviceName;
      }
      final serviceStats = serviceMap.entries.map((e) => ServiceStats(e.key, serviceNames[e.key] ?? 'Unknown', e.value)).toList();

      // 6. Wait Time Analysis (Historical)
      final allCompleted = allTokens.where((t) => t.status == TokenStatus.completed).toList();
      final waitTimes = allCompleted.map((t) => t.completedAt?.difference(t.createdAt).inMinutes ?? 0).toList();
      
      double avgWait = 0;
      int maxWait = 0;
      int minWait = 0;

      if (waitTimes.isNotEmpty) {
        avgWait = waitTimes.fold(0, (a, b) => a + b) / waitTimes.length;
        maxWait = waitTimes.fold(waitTimes.first, (a, b) => a > b ? a : b);
        minWait = waitTimes.fold(waitTimes.first, (a, b) => a < b ? a : b);
      }

      final waitTimeStats = WaitTimeStats(avgWait, maxWait, minWait);

      // 7. Weekly Traffic (Ordered Monday-Sunday)
      final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final weeklyMap = { for (var day in daysOfWeek) day : 0 };
      
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      for (var t in allTokens) {
        if (t.createdAt.isAfter(sevenDaysAgo)) {
          final key = DateFormat('EEEE').format(t.createdAt);
          if (weeklyMap.containsKey(key)) {
            weeklyMap[key] = (weeklyMap[key] ?? 0) + 1;
          }
        }
      }
      final weeklyTraffic = daysOfWeek.map((day) => WeeklyData(day, weeklyMap[day] ?? 0)).toList();

      // 8. Queue Load Analytics
      final queuesSnap = await _db.collection('queues').get();
      final queues = queuesSnap.docs.map((d) => QueueModel.fromDoc(d)).toList();
      int totalWaiting = 0;
      String longestCounter = 'N/A';
      int longestCount = 0;
      String shortestCounter = 'N/A';
      int shortestCount = 999;

      for (var q in queues) {
        final count = q.waitList.length;
        totalWaiting += count;
        if (count > longestCount) {
          longestCount = count;
          longestCounter = q.counterId; // Should ideally map to name, but for brevity using ID
        }
        if (count < shortestCount) {
          shortestCount = count;
          shortestCounter = q.counterId;
        }
      }
      
      final queueLoad = QueueLoadStats(
        totalWaiting: totalWaiting,
        longestQueueCounter: longestCounter,
        longestQueueCount: longestCount,
        shortestQueueCounter: shortestCounter,
        shortestQueueCount: shortestCount == 999 ? 0 : shortestCount,
      );

      // 9. Alerts
      final alerts = <AnalyticsAlert>[];
      if (todayStats.avgWaitTime > 10) {
        alerts.add(AnalyticsAlert(message: 'High Average Wait Time: ${todayStats.avgWaitTime.toStringAsFixed(1)} min', severity: AlertSeverity.warning, type: 'wait_time'));
      }
      if (totalWaiting > 15) {
        alerts.add(AnalyticsAlert(message: 'System Overload: $totalWaiting people in queue', severity: AlertSeverity.critical, type: 'overload'));
      }

      // 10. Predictive
      final avgLast7Days = allTokens.where((t) => t.createdAt.isAfter(now.subtract(const Duration(days: 7)))).length / 7;
      final predictive = PredictiveData(
        expectedTokensTomorrow: avgLast7Days.round(),
        peakHour: 11, // Placeholder logic as requested
      );

      return AnalyticsDashboardData(
        today: todayStats,
        hourlyTraffic: hourlyTraffic,
        branchPerformance: branchStats,
        counterPerformance: counterStats,
        servicePopularity: serviceStats,
        waitTimeAnalysis: waitTimeStats,
        weeklyTraffic: weeklyTraffic,
        queueLoad: queueLoad,
        alerts: alerts,
        predictive: predictive,
      );
    });
  }
}
