import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../routes/navigation_helper.dart';
import '../services/database_service.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  late Medication medication;
  final DatabaseService _databaseService = DatabaseService();
  bool _hasBeenEdited = false;

  @override
  void initState() {
    super.initState();
    medication = widget.medication;
  }

  Future<void> _refreshMedicationData() async {
    try {
      print('=== MedicationDetailScreen: Refreshing medication data ===');
      print('Current medication ID: ${medication.id}');
      print('Current medication times before refresh: ${medication.times}');
      
      final updatedMedication = await _databaseService.getMedication(medication.id!);
      if (updatedMedication != null && mounted) {
        print('Updated medication times from database: ${updatedMedication.times}');
        print('Updated medication times type: ${updatedMedication.times.runtimeType}');
        print('Updated medication times length: ${updatedMedication.times.length}');
        
        setState(() {
          medication = updatedMedication;
        });
        
        print('Medication state updated successfully');
      } else {
        print('No updated medication found or widget not mounted');
      }
    } catch (e) {
      print('Error refreshing medication data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(_hasBeenEdited);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await NavigationHelper.toEditMedication(medication);
              if (result == true) {
                _hasBeenEdited = true;
                await _refreshMedicationData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildScheduleCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Medication Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Medication Name', medication.name),
            const SizedBox(height: 12),
            _buildInfoRow('Dosage', medication.dosage),
            const SizedBox(height: 12),
            _buildInfoRow('Frequency', medication.frequency),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScheduleCard() {
    print('=== MedicationDetailScreen: Building schedule card ===');
    print('Current medication times: ${medication.times}');
    print('Medication times type: ${medication.times.runtimeType}');
    print('Medication times length: ${medication.times.length}');
    print('Joined times string: ${medication.times.join(', ')}');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Medication Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Medication Times', medication.times.join(', ')),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Start Date', 
              DateFormat('yyyy-MM-dd').format(medication.startDate),
            ),
            if (medication.endDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'End Date', 
                DateFormat('yyyy-MM-dd').format(medication.endDate!),
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              'Remaining Days', 
              _calculateRemainingDays(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesCard() {
    if (medication.notes == null || medication.notes!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: Colors.orange[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                medication.notes!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return const SizedBox.shrink();
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
  
  String _calculateRemainingDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (medication.endDate == null) {
      return 'Long-term use';
    }
    
    final endDate = DateTime(
      medication.endDate!.year,
      medication.endDate!.month,
      medication.endDate!.day,
    );
    
    final difference = endDate.difference(today).inDays;
    
    if (difference < 0) {
      return 'Ended';
    } else if (difference == 0) {
      return 'Ends today';
    } else {
      return '$difference days';
    }
  }
}