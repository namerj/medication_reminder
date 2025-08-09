import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/medication.dart';
import '../services/database_service.dart';
import '../routes/navigation_helper.dart';

class MedicationCheckScreen extends StatefulWidget {
  const MedicationCheckScreen({super.key});

  @override
  State<MedicationCheckScreen> createState() => _MedicationCheckScreenState();
}

class _MedicationCheckScreenState extends State<MedicationCheckScreen> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  List<MedicationSchedule> _todaySchedules = [];
  Map<DateTime, Map<String, int>> _calendarData = {}; // 日历概览数据
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodaySchedules();
    _loadCalendarData(_selectedDate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 当应用恢复时重新加载数据
      _refreshData();
    }
  }

  // 刷新数据的方法
  Future<void> _refreshData() async {
    await _loadTodaySchedules();
    await _loadCalendarData(_selectedDate);
  }

  // 公共刷新方法，供外部调用
  Future<void> refreshData() async {
    await _refreshData();
  }



  Future<void> _loadTodaySchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medications = await _databaseService.getActiveMedications();
      final schedules = <MedicationSchedule>[];
      
      final today = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      
      for (final medication in medications) {
        // 检查是否在用药期间
        final medicationStartDay = DateTime(medication.startDate.year, medication.startDate.month, medication.startDate.day);
        final medicationEndDay = medication.endDate != null 
            ? DateTime(medication.endDate!.year, medication.endDate!.month, medication.endDate!.day)
            : null;
        
        if (medicationStartDay.isAfter(today)) continue;
        if (medicationEndDay != null && medicationEndDay.isBefore(today)) continue;
        
        // 为每个时间点创建计划
        for (final time in medication.times) {
          // 从数据库获取实际打卡状态
          final record = await _databaseService.getMedicationRecord(
            medication.id!,
            _selectedDate,
            time,
          );
          
          schedules.add(MedicationSchedule(
            medication: medication,
            time: time,
            date: _selectedDate,
            isCompleted: record?['isCompleted'] == 1,
            recordId: record?['id'],
            actualTime: record?['actualTime'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(record!['actualTime'])
                : null,
          ));
        }
      }
      
      // 按时间排序
      schedules.sort((a, b) => a.time.compareTo(b.time));
      
      setState(() {
        _todaySchedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NavigationHelper.showSnackBar('Loading failed: $e', isError: true);
    }
  }

  // 加载日历概览数据
  Future<void> _loadCalendarData([DateTime? targetMonth]) async {
    try {
      final medications = await _databaseService.getActiveMedications();
      final calendarData = <DateTime, Map<String, int>>{};
      

      
      // 获取指定月份的数据（如果未指定则使用当前选中日期的月份）
      final now = DateTime.now();
      final monthToLoad = targetMonth ?? _selectedDate;
      final startDate = DateTime(monthToLoad.year, monthToLoad.month, 1);
      final endDate = DateTime(monthToLoad.year, monthToLoad.month + 1, 0); // 月末
      
      for (var date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        final dayKey = DateTime(date.year, date.month, date.day);
        int totalSchedules = 0;
        int completedSchedules = 0;
        
        for (final medication in medications) {
          // 检查是否在用药期间
          final medicationStartDay = DateTime(medication.startDate.year, medication.startDate.month, medication.startDate.day);
          final medicationEndDay = medication.endDate != null 
              ? DateTime(medication.endDate!.year, medication.endDate!.month, medication.endDate!.day)
              : null;
          
          if (medicationStartDay.isAfter(dayKey)) continue;
          if (medicationEndDay != null && medicationEndDay.isBefore(dayKey)) continue;
          
          // 确保times不为空且包含有效时间
          if (medication.times.isNotEmpty) {
            for (final time in medication.times) {
              if (time.trim().isNotEmpty) {
                totalSchedules++;
                
                // 检查该时间是否有打卡记录
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

  Future<void> _toggleMedicationCheck(MedicationSchedule schedule) async {
    try {
      final now = DateTime.now();
      
      if (schedule.recordId != null) {
        // 更新现有记录
        await _databaseService.updateMedicationRecord(
          schedule.recordId!,
          {
            'isCompleted': schedule.isCompleted ? 0 : 1,
            'actualTime': schedule.isCompleted ? null : now.millisecondsSinceEpoch,
          },
        );
      } else {
        // 创建新记录
        final recordId = await _databaseService.insertMedicationRecord({
          'medicationId': schedule.medication.id!,
          'scheduledDate': DateTime(
            schedule.date.year,
            schedule.date.month,
            schedule.date.day,
          ).millisecondsSinceEpoch,
          'scheduledTime': schedule.time,
          'actualTime': schedule.isCompleted ? null : now.millisecondsSinceEpoch,
          'isCompleted': schedule.isCompleted ? 0 : 1,
        });
        schedule.recordId = recordId;
      }
      
      setState(() {
        schedule.isCompleted = !schedule.isCompleted;
        schedule.actualTime = schedule.isCompleted ? now : null;
      });
      
      // 重新加载日历数据以更新标记
      _loadCalendarData(_selectedDate);
      
      NavigationHelper.showSnackBar(
        schedule.isCompleted ? 'Check-in completed' : 'Check-in cancelled',
      );
      

    } catch (e) {
      NavigationHelper.showSnackBar('Operation failed: $e', isError: true);
    }
  }

  Future<void> _quickCheckAll() async {
    final uncompletedSchedules = _todaySchedules
        .where((s) => !s.isCompleted && _isSameDay(s.date, DateTime.now()))
        .toList();
    
    if (uncompletedSchedules.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Check-in'),
        content: Text('Are you sure you want to complete the remaining ${uncompletedSchedules.length} medication check-ins for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      for (final schedule in uncompletedSchedules) {
        await _toggleMedicationCheck(schedule);
      }
      NavigationHelper.showSnackBar('All check-ins completed!');
    }
  }

  Future<void> _quickCheckForSelectedDate() async {
    final uncompletedSchedules = _todaySchedules
        .where((s) => !s.isCompleted)
        .toList();
    
    if (uncompletedSchedules.isEmpty) {
      NavigationHelper.showSnackBar('All medications for this date have been checked in');
      return;
    }
    
    final dateStr = DateFormat('MMM dd').format(_selectedDate);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar Check-in'),
        content: Text('Are you sure you want to complete the remaining ${uncompletedSchedules.length} medication check-ins for $dateStr?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      for (final schedule in uncompletedSchedules) {
        await _toggleMedicationCheck(schedule);
      }
      NavigationHelper.showSnackBar('All check-ins for $dateStr completed!');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Check-in'),
        automaticallyImplyLeading: false,
        actions: [
          if (_todaySchedules.any((s) => !s.isCompleted && _isSameDay(s.date, DateTime.now())))
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _quickCheckAll,
              tooltip: 'Quick Check-in',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildScheduleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark 
                ? Colors.grey[700]! 
                : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 日历组件
          TableCalendar<dynamic>(
            firstDay: DateTime(DateTime.now().year - 1, 1, 1),
            lastDay: DateTime(DateTime.now().year + 1, 12, 31),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDate, selectedDay)) {
                setState(() {
                  _selectedDate = selectedDay;
                });
                _loadTodaySchedules();
              } else {
                // 如果点击的是已选中的日期，执行快速打卡
                _quickCheckForSelectedDate();
              }
            },
            onPageChanged: (focusedDay) {
              // 当用户切换月份时，重新加载该月份的数据
              print('Page changed to: $focusedDay');
              setState(() {
                _selectedDate = focusedDay;
              });
              _loadCalendarData(focusedDay);
              _loadTodaySchedules();
            },
            onFormatChanged: (format) {
              if (_isCalendarExpanded != (format == CalendarFormat.month)) {
                setState(() {
                  _isCalendarExpanded = format == CalendarFormat.month;
                });
              }
            },
            calendarFormat: _isCalendarExpanded ? CalendarFormat.month : CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableGestures: AvailableGestures.all,
            eventLoader: (day) {
              final dayKey = DateTime(day.year, day.month, day.day);
              final dayData = _calendarData[dayKey];
              return dayData != null ? <Map<String, int>>[dayData] : <Map<String, int>>[];
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: true,
              rightChevronVisible: true,
              leftChevronIcon: Icon(Icons.chevron_left),
              rightChevronIcon: Icon(Icons.chevron_right),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red[600]),
              holidayTextStyle: TextStyle(color: Colors.red[600]),
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
              markerDecoration: BoxDecoration(
                color: Colors.green[600],
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                return _buildDateMarker(date);
              },
            ),
            locale: 'en_US',
          ),
          // 展开/收起按钮
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark 
                      ? Colors.grey[600]! 
                      : Colors.grey[400]!,
                  width: 0.5,
                ),
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isCalendarExpanded ? 'Collapse Calendar' : 'Expand Monthly Calendar',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建日期标记，显示用药完成情况
  Widget? _buildDateMarker(DateTime date) {
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

  Widget _buildScheduleList() {
    final theme = Theme.of(context);
    if (_todaySchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 80,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No medication plans for today',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                NavigationHelper.toAddMedication();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Medication Plan'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todaySchedules.length,
      itemBuilder: (context, index) {
        final schedule = _todaySchedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(MedicationSchedule schedule) {
    final isOverdue = _isOverdue(schedule);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleMedicationCheck(schedule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 打卡状态图标
              GestureDetector(
                onTap: () => _toggleMedicationCheck(schedule),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: schedule.isCompleted
                        ? Colors.green[600]
                        : isOverdue
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.red[900] : Colors.red[100])
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200]),
                    border: Border.all(
                      color: schedule.isCompleted
                          ? Colors.green[600]!
                          : isOverdue
                              ? Colors.red[400]!
                              : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    schedule.isCompleted
                        ? Icons.check
                        : isOverdue
                            ? Icons.warning
                            : Icons.medication,
                    color: schedule.isCompleted
                        ? Colors.white
                        : isOverdue
                            ? Colors.red[600]
                            : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 用药信息
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // 点击药物名称跳转到详情页面
                    final result = await NavigationHelper.toMedicationDetail(schedule.medication);
                    if (result == true) {
                      // 如果药物信息被编辑，刷新数据
                      await _refreshData();
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              schedule.medication.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: schedule.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: schedule.isCompleted
                                    ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                                    : Colors.blue[600],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dosage: ${schedule.medication.dosage}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildDateRangeText(schedule.medication),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 时间信息
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    schedule.time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOverdue && !schedule.isCompleted
                          ? Colors.red[600]
                          : Colors.blue[600],
                    ),
                  ),
                  if (schedule.isCompleted)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                        if (schedule.actualTime != null)
                          Text(
                            DateFormat('HH:mm').format(schedule.actualTime!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                          ),
                      ],
                    )
                  else if (isOverdue)
                    Text(
                      'Overdue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isOverdue(MedicationSchedule schedule) {
    if (!_isSameDay(schedule.date, DateTime.now())) {
      return false;
    }
    
    final now = DateTime.now();
    final timeParts = schedule.time.split(':');
    final scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    
    return now.isAfter(scheduleTime.add(const Duration(minutes: 30)));
  }

  String _buildDateRangeText(Medication medication) {
    final startDate = DateFormat('MMM dd, yyyy').format(medication.startDate);
    if (medication.endDate != null) {
      final endDate = DateFormat('MMM dd, yyyy').format(medication.endDate!);
      return 'Duration: $startDate - $endDate';
    } else {
      return 'Start: $startDate (No end date)';
    }
  }
}

// 用药计划数据模型
class MedicationSchedule {
  final Medication medication;
  final String time;
  final DateTime date;
  bool isCompleted;
  int? recordId;
  DateTime? actualTime;

  MedicationSchedule({
    required this.medication,
    required this.time,
    required this.date,
    required this.isCompleted,
    this.recordId,
    this.actualTime,
  });
}