class CalendarEvent {
  final String id;
  final String title;
  final String? familyMember;
  final DateTime startTime;
  final DateTime? endTime;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.familyMember,
    required this.startTime,
    this.endTime,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'familyMember': familyMember,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
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
    );
  }
}
