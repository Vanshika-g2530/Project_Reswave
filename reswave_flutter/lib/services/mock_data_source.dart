import '../models/user_model.dart';
import '../models/research_interest.dart';
import '../models/domain_model.dart';
import '../models/learning_resource.dart';
import '../models/paper_item.dart';
import '../models/team_request.dart';
import '../models/mood_entry.dart';
import '../models/opportunity.dart';

class MockDataSource {
  static final List<UserModel> mockUsers = [
    UserModel(
      uid: 'usr-prof-elena',
      email: 'elena.rostova@university.edu',
      displayName: 'Prof. Elena Rostova',
      role: 'Professor / Faculty',
      headline: 'Associate Professor in Human-Centered Computing',
      bio: 'Researching cognitive ergonomics, interfaces, and accessibility.',
      country: 'Germany',
      institution: 'Technical University of Munich',
      discoverable: true,
      preferredCollaborationMode: 'Remote',
    ),
    UserModel(
      uid: 'usr-alex-phd',
      email: 'alex.rivera@cs.cmu.edu',
      displayName: 'Alex Rivera',
      role: 'PhD Scholar',
      headline: 'PhD Candidate in NLP & Trustworthy AI',
      bio: 'Working on benchmark evaluation and citation reliability.',
      country: 'United States',
      institution: 'Carnegie Mellon University',
      discoverable: true,
      preferredCollaborationMode: 'Hybrid',
    ),
  ];

  static final List<ResearchInterest> mockInterests = [
    ResearchInterest(
      id: 'int-01',
      userId: 'usr-alex-phd',
      domainId: 'hci',
      subdomainId: 'Cognitive Ergonomics',
      topicTags: ['cognitive load', 'usability', 'interfaces'],
      proficiency: 'Intermediate',
      status: 'Active research',
      skills: ['user testing', 'experiment design'],
      methods: ['Mixed', 'Experimental'],
      goals: ['Publish', 'Find collaborator'],
    ),
    ResearchInterest(
      id: 'int-02',
      userId: 'usr-alex-phd',
      domainId: 'ai-nlp',
      subdomainId: 'Natural Language Processing',
      topicTags: ['evaluation', 'transformers', 'benchmarks'],
      proficiency: 'Advanced',
      status: 'Active research',
      skills: ['python', 'pytorch'],
      methods: ['Computational'],
      goals: ['Find teammate', 'Publish'],
    ),
  ];

  static final List<LearningResource> mockLearningResources = [
    LearningResource(
      id: 'res-ethics-01',
      title: 'Research Integrity & Academic Ethics Fundamentals',
      category: 'Research basics and research ethics',
      domainTags: ['Ethics', 'All Disciplines'],
      level: 'Beginner',
      format: 'Article',
      summary: 'Authorship ethics, informed participant consent, and data transparency.',
      contentOrUrl: 'Core principles of responsible conduct in academic inquiry.',
      sourceName: 'ResWave Academic Advisory',
      sourceUrl: 'https://reswave.org/guidance/ethics',
      authorOrEditor: 'Dr. Eleanor Vance',
      reviewedDate: '2026-11-10',
    ),
    LearningResource(
      id: 'res-lit-01',
      title: 'Systematic Literature Reviews & Identifying the Gap',
      category: 'Literature review and identifying a research gap',
      domainTags: ['Literature Review', 'HCI'],
      level: 'Intermediate',
      format: 'Checklist',
      summary: '5-step checklist for synthesising papers and locating defensible gaps.',
      contentOrUrl: 'Methodology for comprehensive literature synthesis.',
      sourceName: 'Methodology Collective',
      sourceUrl: 'https://reswave.org/guidance/lit-review',
      authorOrEditor: 'Prof. Marcus Thorne',
      reviewedDate: '2026-11-12',
    ),
  ];

  static final List<PaperItem> mockPapers = [
    PaperItem(
      id: 'paper-01',
      userId: 'usr-alex-phd',
      title: 'Attention Is All You Need',
      authors: ['Vaswani et al.'],
      year: 2017,
      url: 'https://arxiv.org/abs/1706.03762',
      readingStatus: 'Read',
      privateNotes: 'Foundational transformer architecture. Self-attention mechanism.',
    ),
  ];

  static final List<TeamRequestModel> mockTeamRequests = [
    TeamRequestModel(
      id: 'req-01',
      ownerId: 'usr-alex-phd',
      title: 'Empirical Evaluation of Citation Accuracy in LLMs',
      description: 'Designing a benchmark to test citation hallucinations in open-source language models. Looking for a Python developer and statistician.',
      primaryDomain: 'ai-nlp',
      topics: ['evaluation', 'benchmarks', 'citation'],
      skillsNeeded: [
        SkillRequirement(skill: 'python', mustHave: true),
        SkillRequirement(skill: 'data analysis', mustHave: true),
      ],
      rolesNeeded: ['Developer', 'Data Analyst'],
      membersNeeded: 2,
      remainingCapacity: 1,
    ),
  ];

  static final List<MoodEntry> mockMoodEntries = [
    MoodEntry(
      id: 'mood-01',
      userId: 'usr-alex-phd',
      mood: 'Motivated',
      factors: ['Research workload', 'Progress made'],
      intensity: 4,
      privateNote: 'Finished the methodology section draft for the CHI workshop.',
      createdAt: '2026-11-18T10:00:00Z',
    ),
  ];

  static final List<OpportunityModel> mockOpportunities = [
    OpportunityModel(
      id: 'opp-chi-2027',
      type: 'Conference',
      title: 'ACM CHI Conference on Human Factors in Computing Systems',
      organiser: 'ACM SIGCHI',
      description: 'The premier international conference on Human-Computer Interaction.',
      tags: ['HCI', 'UX', 'Accessibility'],
      startDate: '2027-04-24',
      submissionDeadline: '2026-12-15',
      mode: 'Hybrid',
      officialSourceUrl: 'https://chi2027.acm.org',
      lastVerifiedDate: '2026-11-18',
    ),
  ];

  static List<DomainRecommendationResult> getMockRecommendations() {
    return [
      DomainRecommendationResult(
        domainId: 'hci',
        name: 'Human-Computer Interaction (HCI)',
        fitBand: 'Strong',
        score: 85.0,
        reasons: [
          'Matches your interest in computing & psychology',
          'Aligns with your preference for prototyping and user studies',
        ],
        sampleTopics: ['Cognitive Ergonomics', 'Accessibility', 'Explainable AI'],
        requiredSkills: ['Design', 'Programming', 'Interviews'],
        beginnerResources: ['Research Integrity Fundamentals', 'Literature Review Guide'],
      ),
      DomainRecommendationResult(
        domainId: 'ai-nlp',
        name: 'Artificial Intelligence & NLP',
        fitBand: 'Strong',
        score: 75.0,
        reasons: [
          'Matches your interest in technology and computational algorithms',
        ],
        sampleTopics: ['Natural Language Processing', 'Machine Learning', 'Ethics'],
        requiredSkills: ['Python', 'Statistics', 'Data Analysis'],
        beginnerResources: ['Research Ethics'],
      ),
    ];
  }
}
