class SkillRequirement {
  final String skill;
  final bool mustHave;

  SkillRequirement({required this.skill, this.mustHave = true});

  factory SkillRequirement.fromJson(Map<String, dynamic> json) {
    return SkillRequirement(
      skill: json['skill'] ?? '',
      mustHave: json['mustHave'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'skill': skill, 'mustHave': mustHave};
}

class TeamRequestModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String primaryDomain;
  final List<String> relatedDomains;
  final List<String> topics;
  final List<SkillRequirement> skillsNeeded;
  final List<String> rolesNeeded;
  final int membersNeeded;
  final int remainingCapacity;
  final String experiencePref;
  final String commitment;
  final String mode;
  final String status; // Open / Paused / Filled / Closed
  final List<String> applicationQuestions;

  TeamRequestModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.primaryDomain,
    this.relatedDomains = const [],
    required this.topics,
    required this.skillsNeeded,
    required this.rolesNeeded,
    required this.membersNeeded,
    required this.remainingCapacity,
    this.experiencePref = 'Any',
    this.commitment = 'Flexible',
    this.mode = 'Remote',
    this.status = 'Open',
    this.applicationQuestions = const [],
  });

  factory TeamRequestModel.fromJson(Map<String, dynamic> json) {
    return TeamRequestModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      primaryDomain: json['primaryDomain'] ?? '',
      relatedDomains: List<String>.from(json['relatedDomains'] ?? []),
      topics: List<String>.from(json['topics'] ?? []),
      skillsNeeded: (json['skillsNeeded'] as List<dynamic>? ?? [])
          .map((e) => SkillRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
      rolesNeeded: List<String>.from(json['rolesNeeded'] ?? []),
      membersNeeded: json['membersNeeded'] ?? 1,
      remainingCapacity: json['remainingCapacity'] ?? 1,
      experiencePref: json['experiencePref'] ?? 'Any',
      commitment: json['commitment'] ?? 'Flexible',
      mode: json['mode'] ?? 'Remote',
      status: json['status'] ?? 'Open',
      applicationQuestions: List<String>.from(json['applicationQuestions'] ?? []),
    );
  }
}

class ProjectModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> domainTags;
  final List<String> memberIds;
  final String status;
  final String? sourceTeamRequestId;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.domainTags = const [],
    this.memberIds = const [],
    this.status = 'Active',
    this.sourceTeamRequestId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      domainTags: List<String>.from(json['domainTags'] ?? []),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      status: json['status'] ?? 'Active',
      sourceTeamRequestId: json['sourceTeamRequestId'],
    );
  }
}
