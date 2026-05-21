enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;
  final int? count;
  final DateTime? endDate;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.endDate,
    this.daysOfWeek,
    this.dayOfMonth,
  });

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    int? count,
    DateTime? endDate,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    bool clearEndDate = false,
    bool clearCount = false,
    bool clearDaysOfWeek = false,
    bool clearDayOfMonth = false,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      count: clearCount ? null : (count ?? this.count),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      daysOfWeek: clearDaysOfWeek ? null : (daysOfWeek ?? this.daysOfWeek),
      dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
    );
  }

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        'interval': interval,
        if (count != null) 'count': count,
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.daily,
      ),
      interval: json['interval'] ?? 1,
      count: json['count'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : null,
      dayOfMonth: json['dayOfMonth'],
    );
  }

  DateTime? nextOccurrence(DateTime from) {
    DateTime next;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        next = DateTime(from.year, from.month, from.day + interval);
        break;
      case RecurrenceFrequency.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          DateTime? found;
          for (int i = 1; i <= 7; i++) {
            final testDate = DateTime(from.year, from.month, from.day + i);
            if (daysOfWeek!.contains(testDate.weekday)) {
              found = testDate;
              break;
            }
          }
          if (found == null) return null;
          next = found;
        } else {
          next = DateTime(from.year, from.month, from.day + 7 * interval);
        }
        break;
      case RecurrenceFrequency.monthly:
        {
          final day = dayOfMonth ?? from.day;
          final targetMonth = from.month + interval;
          final clampedDay = day.clamp(1, _daysInMonth(from.year, targetMonth));
          next = DateTime(from.year, targetMonth, clampedDay);
        }
        break;
      case RecurrenceFrequency.yearly:
        next = DateTime(from.year + interval, from.month, from.day);
        break;
    }

    if (endDate != null && next.isAfter(endDate!)) return null;
    return next;
  }

  static int _daysInMonth(int year, int month) {
    if (month > 12) {
      year += (month - 1) ~/ 12;
      month = ((month - 1) % 12) + 1;
    }
    if (month < 1) {
      year += (month ~/ 12) - 1;
      month = ((month % 12) + 12) % 12;
      if (month == 0) month = 12;
    }
    if (month == 2) {
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) return 29;
      return 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }
}
