import 'package:flutter/material.dart';
import 'medication_check_screen.dart';
import 'my_medication_screen.dart';
import 'medication_record_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<State<MedicationCheckScreen>> _medicationCheckKey = GlobalKey();
  final GlobalKey<State<MedicationRecordScreen>> _medicationRecordKey = GlobalKey();
  
  late final List<Widget> _screens = [
    MedicationCheckScreen(key: _medicationCheckKey), // Check-in
    const MyMedicationScreen(),    // My Medications
    MedicationRecordScreen(key: _medicationRecordKey), // Records
    const ProfileScreen(),         // Profile
  ];
  
  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.check_circle_outline),
      activeIcon: Icon(Icons.check_circle),
      label: 'Check-in',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.medication_outlined),
      activeIcon: Icon(Icons.medication),
      label: 'Medications',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'Records',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // 当切换到打卡页面时刷新数据
          if (index == 0) {
            final medicationCheckState = _medicationCheckKey.currentState;
            if (medicationCheckState != null && medicationCheckState.mounted) {
              (medicationCheckState as dynamic).refreshData();
            }
          }
          // 当切换到用药记录页面时刷新数据
          else if (index == 2) {
            final medicationRecordState = _medicationRecordKey.currentState;
            if (medicationRecordState != null && medicationRecordState.mounted) {
              (medicationRecordState as dynamic).loadData();
            }
          }
        },
        items: _bottomNavItems,
      ),
    );
  }
}