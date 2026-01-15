class Reminder {
  final String id;
  final String title;
  final String date;
  final String time;

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'].toString(),
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
    );
  }

  factory Reminder.draft({
    required String title,
    required String date,
    required String time,
  }) {
    return Reminder(
      id: '',
      title: title,
      date: date,
      time: time,
    );
  }
}
