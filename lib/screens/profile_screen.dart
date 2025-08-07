import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../routes/navigation_helper.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _appVersion = '1.0.0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          _buildUserHeader(),
          const SizedBox(height: 16),
          _buildSettingsSection(),
          const SizedBox(height: 16),
          _buildDataSection(),
          const SizedBox(height: 16),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[400]!, Colors.blue[600]!],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Reminder User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay consistent, stay healthy',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      title: 'Settings',
      icon: Icons.settings,
      children: [

        Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return _buildListTile(
              title: 'Dark Mode',
              subtitle: themeService.themeModeText,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showThemeModeDialog();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      title: 'Data Management',
      icon: Icons.storage,
      children: [
        _buildListTile(
          title: 'Export Data',
          subtitle: 'Export medication records as JSON file',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _exportData();
          },
        ),
        _buildListTile(
          title: 'Clear Data',
          subtitle: 'Delete all medication data',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showClearDataDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info,
      children: [
        _buildListTile(
          title: 'App Version',
          subtitle: 'v$_appVersion',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showVersionDialog();
          },
        ),

        _buildListTile(
          title: 'Terms of Service',
          subtitle: 'View terms and conditions',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/terms-of-service');
          },
        ),

        _buildListTile(
          title: 'Privacy Policy',
          subtitle: 'View privacy protection policy',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/privacy-policy');
          },
        ),

        _buildListTile(
          title: 'Check for Updates',
          subtitle: 'Check if new version is available',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            NavigationHelper.showSnackBar('You are using the latest version');
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }



  // 导出数据功能
  Future<void> _exportData() async {
    try {
      NavigationHelper.showSnackBar('Exporting data...');
      
      // 获取所有数据
      final allData = await _databaseService.exportAllData();
      
      // 转换为JSON字符串
      final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'medication_data_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      // 写入文件
      await file.writeAsString(jsonString);
      
      // 分享文件
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Medication Reminder Data Export',
        subject: 'Medication Records Data',
      );
      
      NavigationHelper.showSnackBar('Data exported successfully!');
    } catch (e) {
      NavigationHelper.showSnackBar('Export failed: $e', isError: true);
    }
  }

  void _showClearDataDialog() async {
    final confirmed = await NavigationHelper.showConfirmDialog(
      title: 'Clear Data',
      content: 'Are you sure you want to delete all medication data? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
    
    if (confirmed == true) {
      try {
        await _databaseService.clearAllData();
        NavigationHelper.showSnackBar('Data cleared successfully!');
      } catch (e) {
        NavigationHelper.showSnackBar('Clear failed: $e', isError: true);
      }
    }
  }

  void _showThemeModeDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              value: ThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setThemeMode(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              value: ThemeMode.dark,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setThemeMode(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Follow System'),
              value: ThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                themeService.setThemeMode(value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: v$_appVersion'),
            const SizedBox(height: 8),
            const Text('What\'s New:'),
            const SizedBox(height: 4),
            const Text('• Added four-module navigation structure'),
            const Text('• Optimized medication check-in feature'),
            const Text('• Improved medication record statistics'),
            const Text('• Enhanced user interface experience'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}