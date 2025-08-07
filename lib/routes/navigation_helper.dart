import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'app_routes.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  // 导航到首页
  static Future<void> toHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }
  
  // 导航到添加用药页面
  static Future<dynamic> toAddMedication() async {
    return await navigator?.pushNamed(AppRoutes.addMedication);
  }
  
  // 导航到编辑用药页面
  static Future<dynamic> toEditMedication(Medication medication) async {
    return await navigator?.pushNamed(
      AppRoutes.editMedication,
      arguments: medication,
    );
  }
  
  // 导航到用药详情页面
  static Future<dynamic> toMedicationDetail(Medication medication) async {
    return await navigator?.pushNamed(
      AppRoutes.medicationDetail,
      arguments: medication,
    );
  }
  
  // 返回上一页
  static void goBack([dynamic result]) {
    navigator?.pop(result);
  }
  
  // 检查是否可以返回
  static bool canGoBack() {
    return navigator?.canPop() ?? false;
  }
  
  // 显示确认对话框
  static Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
  }) async {
    final context = navigator?.context;
    if (context == null) return null;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  // 显示消息提示
  static void showSnackBar(String message, {bool isError = false}) {
    final context = navigator?.context;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}