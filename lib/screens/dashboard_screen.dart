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
  late DateTime _startDate;
  late DateTime _endDate;
  late Future<double> _periodFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _totalsFuture = _loadTotals();
    _periodFuture = _dao.getTotalInRange(_startDate, _endDate);
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
    final period = await _dao.getTotalInRange(_startDate, _endDate);
    setState(() {
      _totalsFuture = Future.value(totals);
      _periodFuture = Future.value(period);
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _periodFuture = _dao.getTotalInRange(_startDate, _endDate);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _periodFuture = _dao.getTotalInRange(_startDate, _endDate);
      });
    }
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data Inicial',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickStartDate,
                          ),
                        ),
                        controller: TextEditingController(
                            text: DateFormat('yyyy-MM-dd').format(_startDate)),
                        onTap: _pickStartDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data Final',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickEndDate,
                          ),
                        ),
                        controller: TextEditingController(
                            text: DateFormat('yyyy-MM-dd').format(_endDate)),
                        onTap: _pickEndDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<double>(
                  future: _periodFuture,
                  builder: (context, snapshot) {
                    final total = snapshot.data ?? 0;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildTile('Total do per\u00edodo', '...');
                    }
                    return _buildTile(
                        'Total do per\u00edodo', currency.format(total));
                  },
                ),
                const SizedBox(height: 12),
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
