enum ReminderType {
  beforeMeal,
  afterMeal,
  withFood,
  onEmptyStomach,
  beforeBed,
  custom,
}

enum ReminderSound {
  defaultSound,
  gentle,
  urgent,
  custom,
}

enum ReminderPriority {
  low,
  normal,
  high,
  critical,
}

class AdvancedReminder {
  final int? id;
  final int medicationId;
  final ReminderType type;
  final int minutesBefore; // Minutes before scheduled time
  final bool isEnabled;
  final ReminderSound sound;
  final ReminderPriority priority;
  final bool vibrate;
  final bool persistentNotification;
  final int snoozeMinutes;
  final int maxSnoozeCount;
  final String? customMessage;
  final List<int> reminderDays; // 0=Sunday, 1=Monday, etc.
  final DateTime? startDate;
  final DateTime? endDate;

  AdvancedReminder({
    this.id,
    required this.medicationId,
    required this.type,
    this.minutesBefore = 0,
    this.isEnabled = true,
    this.sound = ReminderSound.defaultSound,
    this.priority = ReminderPriority.normal,
    this.vibrate = true,
    this.persistentNotification = false,
    this.snoozeMinutes = 5,
    this.maxSnoozeCount = 3,
    this.customMessage,
    this.reminderDays = const [1, 2, 3, 4, 5, 6, 7], // All days by default
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'type': type.index,
      'minutesBefore': minutesBefore,
      'isEnabled': isEnabled ? 1 : 0,
      'sound': sound.index,
      'priority': priority.index,
      'vibrate': vibrate ? 1 : 0,
      'persistentNotification': persistentNotification ? 1 : 0,
      'snoozeMinutes': snoozeMinutes,
      'maxSnoozeCount': maxSnoozeCount,
      'customMessage': customMessage,
      'reminderDays': reminderDays.join(','),
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
    };
  }

  factory AdvancedReminder.fromMap(Map<String, dynamic> map) {
    return AdvancedReminder(
      id: map['id'],
      medicationId: map['medicationId'],
      type: ReminderType.values[map['type']],
      minutesBefore: map['minutesBefore'] ?? 0,
      isEnabled: map['isEnabled'] == 1,
      sound: ReminderSound.values[map['sound'] ?? 0],
      priority: ReminderPriority.values[map['priority'] ?? 1],
      vibrate: map['vibrate'] == 1,
      persistentNotification: map['persistentNotification'] == 1,
      snoozeMinutes: map['snoozeMinutes'] ?? 5,
      maxSnoozeCount: map['maxSnoozeCount'] ?? 3,
      customMessage: map['customMessage'],
      reminderDays: map['reminderDays'] != null
          ? map['reminderDays'].split(',').map<int>((e) => int.parse(e)).toList()
          : [1, 2, 3, 4, 5, 6, 7],
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
    );
  }

  AdvancedReminder copyWith({
    int? id,
    int? medicationId,
    ReminderType? type,
    int? minutesBefore,
    bool? isEnabled,
    ReminderSound? sound,
    ReminderPriority? priority,
    bool? vibrate,
    bool? persistentNotification,
    int? snoozeMinutes,
    int? maxSnoozeCount,
    String? customMessage,
    List<int>? reminderDays,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AdvancedReminder(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      type: type ?? this.type,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      isEnabled: isEnabled ?? this.isEnabled,
      sound: sound ?? this.sound,
      priority: priority ?? this.priority,
      vibrate: vibrate ?? this.vibrate,
      persistentNotification: persistentNotification ?? this.persistentNotification,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      customMessage: customMessage ?? this.customMessage,
      reminderDays: reminderDays ?? this.reminderDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  String get typeDisplayName {
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

  String get priorityDisplayName {
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

  String get soundDisplayName {
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

class ReminderSettings {
  final bool enableAdvancedReminders;
  final bool enableMissedDoseReminders;
  final int missedDoseReminderMinutes;
  final bool enableRefillReminders;
  final int refillReminderDays;
  final bool enableWeeklyReports;
  final bool enableQuietHours;
  final String quietHoursStart;
  final String quietHoursEnd;

  ReminderSettings({
    this.enableAdvancedReminders = true,
    this.enableMissedDoseReminders = true,
    this.missedDoseReminderMinutes = 30,
    this.enableRefillReminders = true,
    this.refillReminderDays = 3,
    this.enableWeeklyReports = false,
    this.enableQuietHours = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'enableAdvancedReminders': enableAdvancedReminders ? 1 : 0,
      'enableMissedDoseReminders': enableMissedDoseReminders ? 1 : 0,
      'missedDoseReminderMinutes': missedDoseReminderMinutes,
      'enableRefillReminders': enableRefillReminders ? 1 : 0,
      'refillReminderDays': refillReminderDays,
      'enableWeeklyReports': enableWeeklyReports ? 1 : 0,
      'enableQuietHours': enableQuietHours ? 1 : 0,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      enableAdvancedReminders: map['enableAdvancedReminders'] == 1,
      enableMissedDoseReminders: map['enableMissedDoseReminders'] == 1,
      missedDoseReminderMinutes: map['missedDoseReminderMinutes'] ?? 30,
      enableRefillReminders: map['enableRefillReminders'] == 1,
      refillReminderDays: map['refillReminderDays'] ?? 3,
      enableWeeklyReports: map['enableWeeklyReports'] == 1,
      enableQuietHours: map['enableQuietHours'] == 1,
      quietHoursStart: map['quietHoursStart'] ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] ?? '07:00',
    );
  }

  ReminderSettings copyWith({
    bool? enableAdvancedReminders,
    bool? enableMissedDoseReminders,
    int? missedDoseReminderMinutes,
    bool? enableRefillReminders,
    int? refillReminderDays,
    bool? enableWeeklyReports,
    bool? enableQuietHours,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return ReminderSettings(
      enableAdvancedReminders: enableAdvancedReminders ?? this.enableAdvancedReminders,
      enableMissedDoseReminders: enableMissedDoseReminders ?? this.enableMissedDoseReminders,
      missedDoseReminderMinutes: missedDoseReminderMinutes ?? this.missedDoseReminderMinutes,
      enableRefillReminders: enableRefillReminders ?? this.enableRefillReminders,
      refillReminderDays: refillReminderDays ?? this.refillReminderDays,
      enableWeeklyReports: enableWeeklyReports ?? this.enableWeeklyReports,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}