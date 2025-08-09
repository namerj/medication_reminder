import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? editingMedication;
  
  const AddMedicationScreen({super.key, this.editingMedication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();
  
  String _frequency = 'Daily';
  List<String> _selectedTimes = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  bool _isLoading = false;

  final List<String> _frequencyOptions = ['Daily', 'Weekly', 'As Needed'];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }
  
  void _initializeFields() {
    if (widget.editingMedication != null) {
      final medication = widget.editingMedication!;
      print('=== Initializing fields for editing ===');
      print('Original medication ID: ${medication.id}');
      print('Original medication times: ${medication.times}');
      print('Original medication times type: ${medication.times.runtimeType}');
      print('Original medication times length: ${medication.times.length}');
      
      _nameController.text = medication.name;
      _dosageController.text = medication.dosage;
      _frequency = medication.frequency;
      _selectedTimes = List.from(medication.times);
      _startDate = medication.startDate;
      _endDate = medication.endDate;
      _hasEndDate = medication.endDate != null;
      _notesController.text = medication.notes ?? '';
      
      print('Initialized _selectedTimes: $_selectedTimes');
      print('Initialized _selectedTimes type: ${_selectedTimes.runtimeType}');
      print('Initialized _selectedTimes length: ${_selectedTimes.length}');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    print('=== _selectTime called ===');
    print('Current times before selection: $_selectedTimes');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
        // 使用一致的时间格式
        final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        print('Selected time: $timeString');
        print('Formatted time: ${picked.format(context)}');
        
        if (!_selectedTimes.contains(timeString)) {
          print('Adding new time to list');
          setState(() {
            _selectedTimes.add(timeString);
            _selectedTimes.sort();
          });
          print('Times after adding and setState: $_selectedTimes');
          print('Widget will rebuild with new times');
        } else {
          print('Time already exists, showing snackbar');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This time has already been added')),
          );
        }
      } else {
        print('No time selected');
      }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveMedication() async {
    print('=== _saveMedication called ===');
    print('Selected times: $_selectedTimes');
    print('Original medication times: ${widget.editingMedication?.times}');
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medication time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final medication = Medication(
        id: widget.editingMedication?.id,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        times: _selectedTimes,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      print('Medication to save: ${medication.toMap()}');

      late Medication savedMedication;
      
      if (widget.editingMedication != null) {
        // Edit mode: update existing medication plan
        print('Updating existing medication with ID: ${medication.id}');
        await _databaseService.updateMedication(medication);
        savedMedication = medication;
        
        // 验证保存后的数据
        final savedMedicationFromDB = await _databaseService.getMedication(medication.id!);
        print('Saved medication from DB: ${savedMedicationFromDB?.toMap()}');
        
        // Note: Notification functionality removed
      } else {
        // Add mode: create new medication plan
        print('Inserting new medication');
        final id = await _databaseService.insertMedication(medication);
        savedMedication = medication.copyWith(id: id);
      }
      
      // Note: Notification functionality removed

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.editingMedication != null ? 'Medication plan updated' : 'Medication plan saved')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingMedication != null ? 'Edit Medication Plan' : 'Add Medication Plan'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMedication,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildTimesSection(),
            const SizedBox(height: 24),
            _buildDateSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_pharmacy),
                hintText: 'e.g.: 1 tablet, 5ml, 2 capsules',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: _frequencyOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _frequency = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesSection() {
    print('=== Building times section ===');
    print('Current _selectedTimes: $_selectedTimes');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Medication Times',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedTimes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Please add medication times',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTimes.map((time) {
                  return Chip(
                    label: Text(time),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        _selectedTimes.remove(time);
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
              onTap: _selectStartDate,
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Set End Date'),
              subtitle: const Text('If not set, reminders will continue indefinitely'),
              value: _hasEndDate,
              onChanged: (bool value) {
                setState(() {
                  _hasEndDate = value;
                  if (!value) {
                    _endDate = null;
                  }
                });
              },
            ),
            if (_hasEndDate) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('End Date'),
                subtitle: Text(
                  _endDate != null
                      ? DateFormat('yyyy-MM-dd').format(_endDate!)
                      : 'Please select end date',
                ),
                onTap: _selectEndDate,
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'e.g.: Take after meals, precautions, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}