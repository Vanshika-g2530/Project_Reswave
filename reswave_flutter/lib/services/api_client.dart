import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/research_interest.dart';
import '../models/domain_model.dart';
import '../models/learning_resource.dart';
import '../models/paper_item.dart';
import '../models/team_request.dart';
import '../models/mood_entry.dart';
import '../models/opportunity.dart';

class ResWaveApiException implements Exception {
  final String message;
  final int? statusCode;
  ResWaveApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ResWaveApiService {
  static final ResWaveApiService _instance = ResWaveApiService._internal();
  factory ResWaveApiService() => _instance;
  ResWaveApiService._internal();

  // Local Android emulator address: 10.0.2.2 points to host localhost
  static const String baseUrl = 'http://192.168.29.204:8000';

  String? _token;
  UserModel? currentUser;

  bool get isAuthenticated => currentUser != null && _token != null;

  void setAuth(UserModel user, String token) {
    currentUser = user;
    _token = token;
  }

  void logout() {
    currentUser = null;
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ==================== Auth ====================
  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      setAuth(user, data['token']);
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw ResWaveApiException(
          error['detail'] ?? 'Login failed', response.statusCode);
    }
  }

  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String country,
    String? city,
    String? institution,
    String? department,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayName': name,
        'email': email,
        'password': password,
        'role': role,
        'country': country,
        'city': city,
        'institution': institution,
        'department': department,
        'termsAccepted': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      setAuth(user, data['token']);
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw ResWaveApiException(
          error['detail'] ?? 'Registration failed', response.statusCode);
    }
  }

  // ==================== Research Interests (Section 3.6) ====================
  Future<List<ResearchInterest>> getMyInterests() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/users/me/interests'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ResearchInterest.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load research interests', res.statusCode);
    }
  }

  Future<ResearchInterest> addInterest(ResearchInterest interest) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/users/me/interests'),
      headers: _headers,
      body: jsonEncode(interest.toJson()),
    );
    if (res.statusCode == 200) {
      return ResearchInterest.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to save research interest', res.statusCode);
    }
  }

  Future<void> deleteInterest(String intId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/v1/users/me/interests/$intId'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException(
          'Failed to remove research interest', res.statusCode);
    }
  }

  // ==================== Domain Recommendations (Section 4) ====================
  Future<List<DomainRecommendationResult>> getDomainRecommendations(
      Map<String, dynamic> questionnaire) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/domain-recommendations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(questionnaire),
    );
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => DomainRecommendationResult.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to calculate domain recommendations', res.statusCode);
    }
  }

  // ==================== Learning Hub (Section 5) ====================
  Future<List<LearningResource>> getLearningResources(
      {String? domain, String? level, String? format}) async {
    final params = <String, String>{};
    if (domain != null && domain.isNotEmpty) params['domain'] = domain;
    if (level != null && level.isNotEmpty) params['level'] = level;
    if (format != null && format.isNotEmpty) params['format'] = format;

    final uri = Uri.parse('$baseUrl/v1/learning/resources')
        .replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => LearningResource.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load learning resources', res.statusCode);
    }
  }

  // ==================== Paper Library (Section 6.3) ====================
  Future<List<PaperItem>> getMyPapers() async {
    final res =
        await http.get(Uri.parse('$baseUrl/v1/papers'), headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => PaperItem.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load papers', res.statusCode);
    }
  }

  Future<PaperItem> addPaper(PaperItem paper) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/papers'),
      headers: _headers,
      body: jsonEncode(paper.toJson()),
    );
    if (res.statusCode == 200) {
      return PaperItem.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to add paper', res.statusCode);
    }
  }

  Future<void> deletePaper(String paperId) async {
    final res = await http.delete(Uri.parse('$baseUrl/v1/papers/$paperId'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to delete paper', res.statusCode);
    }
  }

  // ==================== Smart Matching (Section 7) ====================
  Future<List<dynamic>> getResearcherMatches(
      {String? domainId, String? topics, String? mode}) async {
    final params = <String, String>{};
    if (domainId != null) params['domainId'] = domainId;
    if (topics != null) params['topics'] = topics;
    if (mode != null) params['mode'] = mode;

    final uri = Uri.parse('$baseUrl/v1/matches/researchers')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to fetch researcher matches', res.statusCode);
    }
  }

  Future<List<dynamic>> getMentorMatches(
      {String? topics, String? helpType, String? level}) async {
    final params = <String, String>{};
    if (topics != null) params['topics'] = topics;
    if (helpType != null) params['helpType'] = helpType;
    if (level != null) params['level'] = level;

    final uri = Uri.parse('$baseUrl/v1/matches/mentors')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to fetch mentor matches', res.statusCode);
    }
  }

  // ==================== Team Requests (Section 7.2) ====================
  Future<List<TeamRequestModel>> getTeamRequests({String? domain}) async {
    final uri = Uri.parse(
        '$baseUrl/v1/team-requests${domain != null ? '?domain=$domain' : ''}');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => TeamRequestModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load team calls', res.statusCode);
    }
  }

  Future<void> applyToTeam(String reqId, List<String> answers) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/team-requests/$reqId/apply'),
      headers: _headers,
      body: jsonEncode({'answers': answers}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Application submission failed', res.statusCode);
    }
  }

  // ==================== Well-Being (Section 10) ====================
  Future<List<MoodEntry>> getMyMoods() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/wellbeing/moods'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => MoodEntry.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load mood entries', res.statusCode);
    }
  }

  Future<MoodEntry> saveMood(MoodEntry entry) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/wellbeing/moods'),
      headers: _headers,
      body: jsonEncode(entry.toJson()),
    );
    if (res.statusCode == 200) {
      return MoodEntry.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to save mood reflection', res.statusCode);
    }
  }

  Future<void> deleteMood(String mid) async {
    final res = await http.delete(Uri.parse('$baseUrl/v1/wellbeing/moods/$mid'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException(
          'Failed to delete mood reflection', res.statusCode);
    }
  }

  Future<List<OpportunityModel>> getOpportunities(
      {String? type, String? mode}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (mode != null) params['mode'] = mode;

    final uri =
        Uri.parse('$baseUrl/v1/opportunities').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => OpportunityModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to fetch opportunities', res.statusCode);
    }
  }
}
