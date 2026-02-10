class Session {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? stickerId;

  Session({this.id, required this.startTime, this.endTime, this.stickerId});

  // Calculate duration in minutes, handling ongoing sessions
  int get durationInMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'sticker_id': stickerId,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      stickerId: map['sticker_id'],
    );
  }

  Session copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? stickerId,
  }) {
    return Session(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stickerId: stickerId ?? this.stickerId,
    );
  }
}
