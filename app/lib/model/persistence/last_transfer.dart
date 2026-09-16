enum LastTransferDirection { sent, received }

enum LastTransferType { image, video, pdf, text, apk, other, multiple }

class LastTransferRecord {
  final LastTransferDirection direction;
  final LastTransferType type;
  final DateTime completedAt;

  const LastTransferRecord({required this.direction, required this.type, required this.completedAt});

  factory LastTransferRecord.fromJson(Map<String, dynamic> json) {
    return LastTransferRecord(
      direction: LastTransferDirection.values.byName(json['direction'] as String),
      type: LastTransferType.values.byName(json['type'] as String),
      completedAt: DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'direction': direction.name,
      'type': type.name,
      'completedAt': completedAt.toUtc().millisecondsSinceEpoch,
    };
  }
}
