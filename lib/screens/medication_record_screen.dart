import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/medication.dart';
import '../services/database_service.dart';
import '../routes/navigation_helper.dart';

class MedicationRecordScreen extends StatefulWidget {
  const MedicationRecordScreen({super.key});

  @override
  State<MedicationRecordScreen> createState() => _MedicationRecordScreenState();
}

class _MedicationRecordScreenState extends State<MedicationRecordScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  List<Medication> _medications = [];
  List<MedicationRecord> _records = [];
  Map<DateTime, Map<String, int>> _calendarData = {}; // Calendar overview data
  bool _isLoading = true;
  String _selectedPeriod = 'This Week';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medications = await _databaseService.getAllMedications();
      // Load actual medication records from database
      final records = await _loadActualRecords(medications);
      
      // Load calendar overview data
      await _loadCalendarData(medications);
      
      setState(() {
        _medications = medications;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NavigationHelper.showSnackBar('Load failed: $e', isError: true);
    }
  }

  // Public refresh method for external calls
  Future<void> loadData() async {
    await _loadData();
  }

  // Load actual medication records from database
  Future<List<MedicationRecord>> _loadActualRecords(List<Medication> medications) async {
    final records = <MedicationRecord>[];
    final now = DateTime.now();
    
    // Load records for the last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      
      for (final medication in medications) {
        // Check if within medication period
        if (medication.startDate.isAfter(date)) continue;
        if (medication.endDate != null && medication.endDate!.isBefore(date)) continue;
        
        for (final time in medication.times) {
          // Get check-in record for this time from database
          final record = await _databaseService.getMedicationRecord(
            medication.id!,
            date,
            time,
          );
          
          if (record != null) {
            // If there's a check-in record, create MedicationRecord object
            final actualTime = record['actualTime'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(record['actualTime'])
                : null;
            
            records.add(MedicationRecord(
              medication: medication,
              scheduledTime: time,
              actualTime: actualTime != null 
                  ? DateFormat('HH:mm').format(actualTime)
                  : time,
              date: date,
              status: record['isCompleted'] == 1 
                  ? RecordStatus.completed 
                  : RecordStatus.missed,
              notes: record['notes'],
            ));
          }
        }
      }
    }
    
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  // Load calendar overview data
  Future<void> _loadCalendarData(List<Medication> medications) async {
    try {
      final calendarData = <DateTime, Map<String, int>>{};
      
      // Get historical data for this month (from 1st to today)
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = now;
      
      for (var date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        final dayKey = DateTime(date.year, date.month, date.day);
        int totalSchedules = 0;
        int completedSchedules = 0;
        
        for (final medication in medications) {
          // Check if within medication period
          if (medication.startDate.isAfter(dayKey)) continue;
          if (medication.endDate != null && medication.endDate!.isBefore(dayKey)) continue;
          
          // 确保times不为空且包含有效时间
          if (medication.times.isNotEmpty) {
            for (final time in medication.times) {
              if (time.trim().isNotEmpty) {
                totalSchedules++;
                
                // Check if there's a check-in record for this time
                final record = await _databaseService.getMedicationRecord(
                  medication.id!,
                  dayKey,
                  time,
                );
                
                if (record?['isCompleted'] == 1) {
                  completedSchedules++;
                }
              }
            }
          }
        }
        
        if (totalSchedules > 0) {
          calendarData[dayKey] = {
            'total': totalSchedules,
            'completed': completedSchedules,
          };
        }
      }
      
      setState(() {
        _calendarData = calendarData;
      });
    } catch (e) {
      print('Failed to load calendar data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Records'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Record List'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecordList(),
                _buildStatistics(),
              ],
            ),
    );
  }

  Widget _buildRecordList() {
    return Column(
      children: [
        _buildPeriodSelector(),
        Expanded(
          child: _records.isEmpty
              ? _buildEmptyState()
              : _buildRecordListView(),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'All'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Time Range:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period;
                          });
                          // TODO: Filter records based on selected time range
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordListView() {
    // Group records by date
    final groupedRecords = <String, List<MedicationRecord>>{};
    for (final record in _records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      groupedRecords.putIfAbsent(dateKey, () => []).add(record);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final dateKey = groupedRecords.keys.elementAt(index);
        final dayRecords = groupedRecords[dateKey]!;
        return _buildDayRecordGroup(dateKey, dayRecords);
      },
    );
  }

  Widget _buildDayRecordGroup(String dateKey, List<MedicationRecord> records) {
    final date = DateTime.parse(dateKey);
    final isToday = _isSameDay(date, DateTime.now());
    final completedCount = records.where((r) => r.status == RecordStatus.completed).length;
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? Colors.blue[900]?.withOpacity(0.3)
                  : Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('MMM dd, EEEE').format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount/${records.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...records.map((record) => _buildRecordItem(record)),
        ],
      ),
    );
  }

  Widget _buildRecordItem(MedicationRecord record) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 状态图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(record.status),
            ),
            child: Icon(
              _getStatusIcon(record.status),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // 用药信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.medication.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Dosage: ${record.medication.dosage}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                if (record.notes != null)
                  Text(
                    record.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // 时间信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.scheduledTime,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _getStatusText(record.status),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(record.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverallStats(),
          const SizedBox(height: 16),
          _buildCalendarOverview(),
          const SizedBox(height: 16),
          _buildWeeklyChart(),
          const SizedBox(height: 16),
          _buildMedicationStats(),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final totalRecords = _records.length;
    final completedRecords = _records.where((r) => r.status == RecordStatus.completed).length;
    final missedRecords = _records.where((r) => r.status == RecordStatus.missed).length;
    final adherenceRate = totalRecords > 0 ? (completedRecords / totalRecords * 100) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Adherence Rate',
                    '${adherenceRate.toStringAsFixed(1)}%',
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '$completedRecords',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Missed',
                    '$missedRecords',
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medication Calendar Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar<dynamic>(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now(),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: (day) {
                final dayKey = DateTime(day.year, day.month, day.day);
                final dayData = _calendarData[dayKey];
                return dayData != null ? <Map<String, int>>[dayData] : <Map<String, int>>[];
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(Icons.chevron_left),
                rightChevronIcon: Icon(Icons.chevron_right),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[600]),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange[400],
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return _buildCalendarMarker(date);
                },
              ),
              locale: 'en_US',
            ),
            const SizedBox(height: 16),
            _buildCalendarLegend(),
          ],
        ),
      ),
    );
  }

  Widget? _buildCalendarMarker(DateTime date) {
    final dayKey = DateTime(date.year, date.month, date.day);
    final dayData = _calendarData[dayKey];
    
    if (dayData == null || dayData['total'] == 0) {
      return null;
    }
    
    final total = dayData['total']!;
    final completed = dayData['completed']!;
    final completionRate = completed / total;
    
    Color markerColor;
    if (completionRate == 1.0) {
      markerColor = Colors.green; // 全部完成
    } else if (completionRate >= 0.5) {
      markerColor = Colors.orange; // 部分完成
    } else {
      markerColor = Colors.red; // 大部分未完成
    }
    
    return Positioned(
      bottom: 1,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.green, 'All Completed'),
        _buildLegendItem(Colors.orange, 'Partially Completed'),
        _buildLegendItem(Colors.red, 'Mostly Incomplete'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: Center(
                child: Text(
                  'Chart feature to be implemented',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationStats() {
    final medicationStats = <String, Map<String, int>>{};
    
    for (final record in _records) {
      final name = record.medication.name;
      medicationStats.putIfAbsent(name, () => {'completed': 0, 'missed': 0});
      
      if (record.status == RecordStatus.completed) {
        medicationStats[name]!['completed'] = medicationStats[name]!['completed']! + 1;
      } else if (record.status == RecordStatus.missed) {
        medicationStats[name]!['missed'] = medicationStats[name]!['missed']! + 1;
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Individual Medication Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...medicationStats.entries.map((entry) {
              final name = entry.key;
              final completed = entry.value['completed']!;
              final missed = entry.value['missed']!;
              final total = completed + missed;
              final rate = total > 0 ? (completed / total * 100) : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Completed $completed times, missed $missed times',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rate >= 80 ? Colors.green : rate >= 60 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No medication records yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getStatusColor(RecordStatus status) {
    switch (status) {
      case RecordStatus.completed:
        return Colors.green;
      case RecordStatus.missed:
        return Colors.red;
      case RecordStatus.delayed:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(RecordStatus status) {
    switch (status) {
      case RecordStatus.completed:
        return Icons.check;
      case RecordStatus.missed:
        return Icons.close;
      case RecordStatus.delayed:
        return Icons.schedule;
    }
  }

  String _getStatusText(RecordStatus status) {
    switch (status) {
      case RecordStatus.completed:
        return 'Completed';
      case RecordStatus.missed:
        return 'Missed';
      case RecordStatus.delayed:
        return 'Delayed';
    }
  }
}

// 用药记录数据模型
class MedicationRecord {
  final Medication medication;
  final String scheduledTime;
  final String actualTime;
  final DateTime date;
  final RecordStatus status;
  final String? notes;

  MedicationRecord({
    required this.medication,
    required this.scheduledTime,
    required this.actualTime,
    required this.date,
    required this.status,
    this.notes,
  });
}

enum RecordStatus {
  completed,
  missed,
  delayed,
}