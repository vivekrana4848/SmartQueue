import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsDashboardData {
  final TodayStats today;
  final List<HourlyData> hourlyTraffic;
  final List<BranchStats> branchPerformance;
  final List<CounterStats> counterPerformance;
  final List<ServiceStats> servicePopularity;
  final WaitTimeStats waitTimeAnalysis;
  final List<WeeklyData> weeklyTraffic;
  final QueueLoadStats queueLoad;
  final List<AnalyticsAlert> alerts;
  final PredictiveData predictive;

  AnalyticsDashboardData({
    required this.today,
    required this.hourlyTraffic,
    required this.branchPerformance,
    required this.counterPerformance,
    required this.servicePopularity,
    required this.waitTimeAnalysis,
    required this.weeklyTraffic,
    required this.queueLoad,
    required this.alerts,
    required this.predictive,
  });
}

class TodayStats {
  final int total;
  final int completed;
  final int pending;
  final int skipped;
  final double avgWaitTime;
  final int activeCounters;

  TodayStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.skipped,
    required this.avgWaitTime,
    required this.activeCounters,
  });
}

class HourlyData {
  final int hour;
  final int count;
  HourlyData(this.hour, this.count);
}

class BranchStats {
  final String branchId;
  final String branchName;
  final int tokenCount;
  BranchStats(this.branchId, this.branchName, this.tokenCount);
}

class CounterStats {
  final String counterId;
  final String counterName;
  final int tokensServed;
  final double avgServiceTimeMinutes;
  CounterStats(this.counterId, this.counterName, this.tokensServed, this.avgServiceTimeMinutes);
}

class ServiceStats {
  final String serviceId;
  final String serviceName;
  final int count;
  ServiceStats(this.serviceId, this.serviceName, this.count);
}

class WaitTimeStats {
  final double avgWaitMinutes;
  final int maxWaitMinutes;
  final int minWaitMinutes;
  WaitTimeStats(this.avgWaitMinutes, this.maxWaitMinutes, this.minWaitMinutes);
}

class WeeklyData {
  final String date; // e.g., "Monday"
  final int count;
  WeeklyData(this.date, this.count);
}

class QueueLoadStats {
  final int totalWaiting;
  final String longestQueueCounter;
  final int longestQueueCount;
  final String shortestQueueCounter;
  final int shortestQueueCount;

  QueueLoadStats({
    required this.totalWaiting,
    required this.longestQueueCounter,
    required this.longestQueueCount,
    required this.shortestQueueCounter,
    required this.shortestQueueCount,
  });
}

class AnalyticsAlert {
  final String message;
  final AlertSeverity severity;
  final String type; // e.g., "wait_time", "overload"

  AnalyticsAlert({required this.message, required this.severity, required this.type});
}

enum AlertSeverity { warning, critical, info }

class PredictiveData {
  final int expectedTokensTomorrow;
  final int peakHour;

  PredictiveData({required this.expectedTokensTomorrow, required this.peakHour});
}
