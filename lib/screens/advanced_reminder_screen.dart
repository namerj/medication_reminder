import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/advanced_reminder.dart';
import '../services/database_service.dart';

class AdvancedReminderScreen extends StatefulWidget {
  final Medication medication;

  const AdvancedReminderScreen({Key? key, required this.medication}) : super(key: key);

  @override
  _AdvancedReminderScreenState createState() => _AdvancedReminderScreenState();
}

class _AdvancedReminderScreenState extends State<AdvancedReminderScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<AdvancedReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _databaseService.getAdvancedReminders(widget.medication.id!);
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reminders: $e')),
      );
    }
  }

  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAdvancedReminderScreen(
          medicationId: widget.medication.id!,
        ),
      ),
    );
    
    if (result == true) {
      _loadReminders();
    }
  }

  Future<void> _editReminder(AdvancedReminder reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdvancedReminderScreen(
          reminder: reminder,
        ),
      ),
    );
    
    if (result == true) {
      _loadReminders();
    }
  }

  Future<void> _deleteReminder(AdvancedReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteAdvancedReminder(reminder.id!);
        _loadReminders();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reminder: $e')),
        );
      }
    }
  }

  Future<void> _toggleReminder(AdvancedReminder reminder) async {
    try {
      final updatedReminder = reminder.copyWith(isEnabled: !reminder.isEnabled);
      await _databaseService.updateAdvancedReminder(updatedReminder);
      _loadReminders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Reminders - ${widget.medication.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No advanced reminders set',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a reminder',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(AdvancedReminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.typeDisplayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildReminderDescription(reminder),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: (_) => _toggleReminder(reminder),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Priority', reminder.priorityDisplayName),
                const SizedBox(width: 8),
                _buildInfoChip('Sound', reminder.soundDisplayName),
                if (reminder.minutesBefore > 0) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip('Before', '${reminder.minutesBefore}min'),
                ]
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editReminder(reminder),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteReminder(reminder),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _buildReminderDescription(AdvancedReminder reminder) {
    final days = _formatReminderDays(reminder.reminderDays);
    String description = 'Active on $days';
    
    if (reminder.startDate != null || reminder.endDate != null) {
      description += '\n';
      if (reminder.startDate != null) {
        description += 'From ${_formatDate(reminder.startDate!)}';
      }
      if (reminder.endDate != null) {
        description += ' to ${_formatDate(reminder.endDate!)}';
      }
    }
    
    return description;
  }

  String _formatReminderDays(List<int> days) {
    if (days.length == 7) return 'All days';
    
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((day) => dayNames[day]).join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AddAdvancedReminderScreen extends StatefulWidget {
  final int medicationId;

  const AddAdvancedReminderScreen({Key? key, required this.medicationId}) : super(key: key);

  @override
  _AddAdvancedReminderScreenState createState() => _AddAdvancedReminderScreenState();
}

class _AddAdvancedReminderScreenState extends State<AddAdvancedReminderScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  ReminderType _selectedType = ReminderType.beforeMeal;
  int _minutesBefore = 0;
  ReminderSound _selectedSound = ReminderSound.defaultSound;
  ReminderPriority _selectedPriority = ReminderPriority.normal;
  bool _vibrate = true;
  bool _persistentNotification = false;
  int _snoozeMinutes = 5;
  int _maxSnoozeCount = 3;
  String? _customMessage;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  DateTime? _startDate;
  DateTime? _endDate;
  
  final TextEditingController _customMessageController = TextEditingController();

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final reminder = AdvancedReminder(
        medicationId: widget.medicationId,
        type: _selectedType,
        minutesBefore: _minutesBefore,
        sound: _selectedSound,
        priority: _selectedPriority,
        vibrate: _vibrate,
        persistentNotification: _persistentNotification,
        snoozeMinutes: _snoozeMinutes,
        maxSnoozeCount: _maxSnoozeCount,
        customMessage: _customMessage?.isNotEmpty == true ? _customMessage : null,
        reminderDays: _selectedDays,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      await _databaseService.insertAdvancedReminder(reminder);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advanced reminder added successfully')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Advanced Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSection(),
            const SizedBox(height: 24),
            _buildTimingSection(),
            const SizedBox(height: 24),
            _buildNotificationSection(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildDateRangeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: ReminderType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            if (_selectedType == ReminderType.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customMessageController,
                decoration: const InputDecoration(
                  labelText: 'Custom Message',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your custom reminder message',
                ),
                maxLines: 2,
                onChanged: (value) {
                  _customMessage = value;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _minutesBefore.toString(),
              decoration: const InputDecoration(
                labelText: 'Minutes Before Scheduled Time',
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter minutes before';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onChanged: (value) {
                _minutesBefore = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: ReminderPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityDisplayName(priority)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderSound>(
              value: _selectedSound,
              decoration: const InputDecoration(
                labelText: 'Sound',
                border: OutlineInputBorder(),
              ),
              items: ReminderSound.values.map((sound) {
                return DropdownMenuItem(
                  value: sound,
                  child: Text(_getSoundDisplayName(sound)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSound = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate when notification appears'),
              value: _vibrate,
              onChanged: (value) {
                setState(() {
                  _vibrate = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Persistent Notification'),
              subtitle: const Text('Keep notification until dismissed'),
              value: _persistentNotification,
              onChanged: (value) {
                setState(() {
                  _persistentNotification = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Active Days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildDaySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return FilterChip(
          label: Text(dayNames[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
        );
      }),
    );
  }

  Widget _buildDateRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate != null 
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate != null 
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(ReminderType type) {
    switch (type) {
      case ReminderType.beforeMeal:
        return 'Before Meal';
      case ReminderType.afterMeal:
        return 'After Meal';
      case ReminderType.withFood:
        return 'With Food';
      case ReminderType.onEmptyStomach:
        return 'On Empty Stomach';
      case ReminderType.beforeBed:
        return 'Before Bed';
      case ReminderType.custom:
        return 'Custom';
    }
  }

  String _getPriorityDisplayName(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.normal:
        return 'Normal';
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.critical:
        return 'Critical';
    }
  }

  String _getSoundDisplayName(ReminderSound sound) {
    switch (sound) {
      case ReminderSound.defaultSound:
        return 'Default';
      case ReminderSound.gentle:
        return 'Gentle';
      case ReminderSound.urgent:
        return 'Urgent';
      case ReminderSound.custom:
        return 'Custom';
    }
  }
}

class EditAdvancedReminderScreen extends StatefulWidget {
  final AdvancedReminder reminder;

  const EditAdvancedReminderScreen({Key? key, required this.reminder}) : super(key: key);

  @override
  _EditAdvancedReminderScreenState createState() => _EditAdvancedReminderScreenState();
}

class _EditAdvancedReminderScreenState extends State<EditAdvancedReminderScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  late ReminderType _selectedType;
  late int _minutesBefore;
  late ReminderSound _selectedSound;
  late ReminderPriority _selectedPriority;
  late bool _vibrate;
  late bool _persistentNotification;
  late int _snoozeMinutes;
  late int _maxSnoozeCount;
  String? _customMessage;
  late List<int> _selectedDays;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final TextEditingController _customMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _selectedType = widget.reminder.type;
    _minutesBefore = widget.reminder.minutesBefore;
    _selectedSound = widget.reminder.sound;
    _selectedPriority = widget.reminder.priority;
    _vibrate = widget.reminder.vibrate;
    _persistentNotification = widget.reminder.persistentNotification;
    _snoozeMinutes = widget.reminder.snoozeMinutes;
    _maxSnoozeCount = widget.reminder.maxSnoozeCount;
    _customMessage = widget.reminder.customMessage;
    _selectedDays = List.from(widget.reminder.reminderDays);
    _startDate = widget.reminder.startDate;
    _endDate = widget.reminder.endDate;
    
    if (_customMessage != null) {
      _customMessageController.text = _customMessage!;
    }
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final updatedReminder = widget.reminder.copyWith(
        type: _selectedType,
        minutesBefore: _minutesBefore,
        sound: _selectedSound,
        priority: _selectedPriority,
        vibrate: _vibrate,
        persistentNotification: _persistentNotification,
        snoozeMinutes: _snoozeMinutes,
        maxSnoozeCount: _maxSnoozeCount,
        customMessage: _customMessage?.isNotEmpty == true ? _customMessage : null,
        reminderDays: _selectedDays,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      await _databaseService.updateAdvancedReminder(updatedReminder);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advanced reminder updated successfully')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Advanced Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSection(),
            const SizedBox(height: 24),
            _buildTimingSection(),
            const SizedBox(height: 24),
            _buildNotificationSection(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildDateRangeSection(),
          ],
        ),
      ),
    );
  }

  // The rest of the methods are identical to AddAdvancedReminderScreen
  // (copying the same build methods to avoid repetition)
  
  Widget _buildTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: ReminderType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            if (_selectedType == ReminderType.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customMessageController,
                decoration: const InputDecoration(
                  labelText: 'Custom Message',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your custom reminder message',
                ),
                maxLines: 2,
                onChanged: (value) {
                  _customMessage = value;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _minutesBefore.toString(),
              decoration: const InputDecoration(
                labelText: 'Minutes Before Scheduled Time',
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter minutes before';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onChanged: (value) {
                _minutesBefore = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: ReminderPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityDisplayName(priority)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderSound>(
              value: _selectedSound,
              decoration: const InputDecoration(
                labelText: 'Sound',
                border: OutlineInputBorder(),
              ),
              items: ReminderSound.values.map((sound) {
                return DropdownMenuItem(
                  value: sound,
                  child: Text(_getSoundDisplayName(sound)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSound = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate when notification appears'),
              value: _vibrate,
              onChanged: (value) {
                setState(() {
                  _vibrate = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Persistent Notification'),
              subtitle: const Text('Keep notification until dismissed'),
              value: _persistentNotification,
              onChanged: (value) {
                setState(() {
                  _persistentNotification = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Active Days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildDaySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return FilterChip(
          label: Text(dayNames[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
        );
      }),
    );
  }

  Widget _buildDateRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate != null 
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate != null 
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(ReminderType type) {
    switch (type) {
      case ReminderType.beforeMeal:
        return 'Before Meal';
      case ReminderType.afterMeal:
        return 'After Meal';
      case ReminderType.withFood:
        return 'With Food';
      case ReminderType.onEmptyStomach:
        return 'On Empty Stomach';
      case ReminderType.beforeBed:
        return 'Before Bed';
      case ReminderType.custom:
        return 'Custom';
    }
  }

  String _getPriorityDisplayName(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.normal:
        return 'Normal';
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.critical:
        return 'Critical';
    }
  }

  String _getSoundDisplayName(ReminderSound sound) {
    switch (sound) {
      case ReminderSound.defaultSound:
        return 'Default';
      case ReminderSound.gentle:
        return 'Gentle';
      case ReminderSound.urgent:
        return 'Urgent';
      case ReminderSound.custom:
        return 'Custom';
    }
  }
}