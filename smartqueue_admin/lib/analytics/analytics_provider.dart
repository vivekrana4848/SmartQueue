import 'package:flutter/material.dart';
import 'analytics_models.dart';
import 'analytics_service.dart';

class EnterpriseAnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService();
  
  AnalyticsDashboardData? _data;
  AnalyticsDashboardData? get data => _data;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Stream<AnalyticsDashboardData>? _analyticsStream;

  void init() {
    _analyticsStream = _service.streamFullAnalytics();
    _analyticsStream?.listen(
      (newData) {
        _data = newData;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }
}
