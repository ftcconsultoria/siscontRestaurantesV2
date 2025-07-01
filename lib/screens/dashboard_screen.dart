import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/order_dao.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final OrderDao _dao = OrderDao();
  late Future<Map<String, double>> _totalsFuture;

  @override
  void initState() {
    super.initState();
    _totalsFuture = _loadTotals();
  }

  Future<Map<String, double>> _loadTotals() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startWeek = today.subtract(Duration(days: today.weekday - 1));
    final startMonth = DateTime(now.year, now.month, 1);
    final todayTotal = await _dao.getTotalInRange(today, today);
    final weekTotal = await _dao.getTotalInRange(startWeek, today);
    final monthTotal = await _dao.getTotalInRange(startMonth, today);
    return {
      'today': todayTotal,
      'week': weekTotal,
      'month': monthTotal,
    };
  }

  Future<void> _refresh() async {
    final totals = await _loadTotals();
    setState(() {
      _totalsFuture = Future.value(totals);
    });
  }

  Widget _buildTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<Map<String, double>>(
        future: _totalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final totals = snapshot.data ?? {};
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildTile('Total vendido hoje',
                    currency.format(totals['today'] ?? 0)),
                const SizedBox(height: 12),
                _buildTile('Total vendido na semana',
                    currency.format(totals['week'] ?? 0)),
                const SizedBox(height: 12),
                _buildTile('Total vendido no m\u00eas',
                    currency.format(totals['month'] ?? 0)),
              ],
            ),
          );
        },
      ),
    );
  }
}
