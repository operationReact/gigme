import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class HomeJobDto {
  final int id; final String title; final int budgetCents; final String status; final String? clientEmail;
  HomeJobDto({required this.id, required this.title, required this.budgetCents, required this.status, this.clientEmail});
  factory HomeJobDto.fromJson(Map<String,dynamic> j)=> HomeJobDto(id: j['id'], title: j['title'], budgetCents: j['budgetCents'], status: j['status'], clientEmail: j['clientEmail']);
}
class HomePortfolioDto { final int id; final String title; final String? imageUrl; HomePortfolioDto({required this.id, required this.title, this.imageUrl}); factory HomePortfolioDto.fromJson(Map<String,dynamic> j)=> HomePortfolioDto(id:j['id'], title:j['title'], imageUrl:j['imageUrl']); }
class FreelancerHomeDto {
  final int userId; final String email; final String? displayName; final String? professionalTitle; final String? skillsCsv;
  final int assignedCount; final int completedCount; final int portfolioCount; final int distinctClients; final int totalBudgetCents; final int successPercent;
  final List<HomeJobDto> recentAssignedJobs; final List<HomeJobDto> recommendedJobs; final List<HomePortfolioDto> portfolioItems;
  FreelancerHomeDto({required this.userId, required this.email, this.displayName, this.professionalTitle, this.skillsCsv, required this.assignedCount, required this.completedCount, required this.portfolioCount, required this.distinctClients, required this.totalBudgetCents, required this.successPercent, required this.recentAssignedJobs, required this.recommendedJobs, required this.portfolioItems});
  factory FreelancerHomeDto.fromJson(Map<String,dynamic> j)=> FreelancerHomeDto(
    userId: j['userId'], email: j['email'], displayName: j['displayName'], professionalTitle: j['professionalTitle'], skillsCsv: j['skillsCsv'],
    assignedCount: j['assignedCount'], completedCount: j['completedCount'], portfolioCount: j['portfolioCount'], distinctClients: j['distinctClients'], totalBudgetCents: j['totalBudgetCents'], successPercent: j['successPercent'],
    recentAssignedJobs: (j['recentAssignedJobs'] as List).map((e)=> HomeJobDto.fromJson(e)).toList(),
    recommendedJobs: (j['recommendedJobs'] as List).map((e)=> HomeJobDto.fromJson(e)).toList(),
    portfolioItems: (j['portfolioItems'] as List).map((e)=> HomePortfolioDto.fromJson(e)).toList(),
  );
}
class HomeApi { final _client = ApiClient.instance; Future<FreelancerHomeDto> getHome(int userId) async { final http.Response res = await _client.get('/api/freelancers/$userId/home'); if(res.statusCode==200){ return FreelancerHomeDto.fromJson(jsonDecode(res.body)); } throw Exception('Failed home load ${res.statusCode}'); }}

