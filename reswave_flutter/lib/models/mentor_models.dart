class MentorProfileModel {
  final String userId;
  final bool mentorshipEnabled;
  final List<String> expertiseTags;
  final List<String> helpTypes;
  final List<String> menteeLevels;
  final List<String> formats;
  final String availability;
  final int maxCapacity;
  final int activeMenteesCount;
  final String preferredFrequency;
  final String timezone;
  final String visibility;

  MentorProfileModel({
    required this.userId,
    required this.mentorshipEnabled,
    required this.expertiseTags,
    required this.helpTypes,
    required this.menteeLevels,
    required this.formats,
    this.availability = 'Available',
    this.maxCapacity = 3,
    this.activeMenteesCount = 0,
    this.preferredFrequency = 'Bi-weekly',
    this.timezone = 'UTC',
    this.visibility = 'Public to members',
  });

  factory MentorProfileModel.fromJson(Map<String, dynamic> json) {
    return MentorProfileModel(
      userId: json['userId'] ?? '',
      mentorshipEnabled: json['mentorshipEnabled'] ?? false,
      expertiseTags: List<String>.from(json['expertiseTags'] ?? []),
      helpTypes: List<String>.from(json['helpTypes'] ?? []),
      menteeLevels: List<String>.from(json['menteeLevels'] ?? []),
      formats: List<String>.from(json['formats'] ?? []),
      availability: json['availability'] ?? 'Available',
      maxCapacity: json['maxCapacity'] ?? 3,
      activeMenteesCount: json['activeMenteesCount'] ?? 0,
      preferredFrequency: json['preferredFrequency'] ?? 'Bi-weekly',
      timezone: json['timezone'] ?? 'UTC',
      visibility: json['visibility'] ?? 'Public to members',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mentorshipEnabled': mentorshipEnabled,
      'expertiseTags': expertiseTags,
      'helpTypes': helpTypes,
      'menteeLevels': menteeLevels,
      'formats': formats,
      'availability': availability,
      'maxCapacity': maxCapacity,
      'activeMenteesCount': activeMenteesCount,
      'preferredFrequency': preferredFrequency,
      'timezone': timezone,
      'visibility': visibility,
    };
  }
}

class MentorRequestModel {
  final String id;
  final String menteeId;
  final String menteeName;
  final String? menteeRole;
  final String mentorId;
  final String mentorName;
  final String helpType;
  final String context;
  final String format;
  final String frequency;
  final String timezone;
  final String? questions;
  final String status;
  final String createdAt;

  MentorRequestModel({
    required this.id,
    required this.menteeId,
    required this.menteeName,
    this.menteeRole,
    required this.mentorId,
    required this.mentorName,
    required this.helpType,
    required this.context,
    required this.format,
    required this.frequency,
    required this.timezone,
    this.questions,
    required this.status,
    required this.createdAt,
  });

  factory MentorRequestModel.fromJson(Map<String, dynamic> json) {
    return MentorRequestModel(
      id: json['id'] ?? '',
      menteeId: json['menteeId'] ?? '',
      menteeName: json['menteeName'] ?? '',
      menteeRole: json['menteeRole'],
      mentorId: json['mentorId'] ?? '',
      mentorName: json['mentorName'] ?? '',
      helpType: json['helpType'] ?? '',
      context: json['context'] ?? '',
      format: json['format'] ?? 'Remote',
      frequency: json['frequency'] ?? 'Bi-weekly',
      timezone: json['timezone'] ?? 'UTC',
      questions: json['questions'],
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
