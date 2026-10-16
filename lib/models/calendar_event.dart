class CalendarEvent {
  final String id;
  final String title;
  final String? familyMember;
  final DateTime startTime;
  final DateTime? endTime;
  final String? recurrenceRule;
  final List<DateTime> skipDates;
  final DateTime? recurrenceInstanceDate;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.familyMember,
    required this.startTime,
    this.endTime,
    this.recurrenceRule,
    this.skipDates = const [],
    this.recurrenceInstanceDate,
  });

  bool get isRecurring => recurrenceRule != null;

  CalendarEvent occurrenceAt(DateTime startTime) {
    return CalendarEvent(
      id: id,
      title: title,
      familyMember: familyMember,
      startTime: startTime,
      endTime: endTime?.add(startTime.difference(this.startTime)),
      recurrenceRule: recurrenceRule,
      skipDates: skipDates,
      recurrenceInstanceDate: DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'familyMember': familyMember,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'recurrenceRule': recurrenceRule,
    'skipDates': skipDates.map(_dateOnlyString).toList(),
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      familyMember: json['familyMember'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      recurrenceRule: json['recurrenceRule'] as String?,
      skipDates: (json['skipDates'] as List<dynamic>? ?? [])
          .map((date) => DateTime.parse(date as String))
          .toList(),
    );
  }

  static String _dateOnlyString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
