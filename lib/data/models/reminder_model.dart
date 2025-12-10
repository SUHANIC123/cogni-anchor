class Reminder {
  final int? id; // New field for API response
  final String title;
  final String date;
  final String time;

  Reminder({
    this.id, // Make ID nullable/optional for creation
    required this.title,
    required this.date,
    required this.time,
  });

  // Factory constructor to create a Reminder object from JSON response
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as int,
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
    );
  }
}