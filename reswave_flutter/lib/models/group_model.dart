class GroupModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String primaryDomain;
  final List<String> topics;
  final String purpose;
  final String membershipMode;
  final String visibility;
  final String rules;
  final int memberCount;
  final String status;
  final String createdAt;

  GroupModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.primaryDomain,
    required this.topics,
    required this.purpose,
    required this.membershipMode,
    required this.visibility,
    required this.rules,
    required this.memberCount,
    required this.status,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      primaryDomain: json['primaryDomain'] ?? '',
      topics: List<String>.from(json['topics'] ?? []),
      purpose: json['purpose'] ?? '',
      membershipMode: json['membershipMode'] ?? 'Open',
      visibility: json['visibility'] ?? 'Discoverable',
      rules: json['rules'] ?? '',
      memberCount: json['memberCount'] ?? 1,
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
