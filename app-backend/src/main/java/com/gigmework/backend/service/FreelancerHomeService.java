package com.gigmework.backend.service;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.repo.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class FreelancerHomeService {
    private final UserAccountRepository userRepo;
    private final FreelancerProfileRepository profileRepo;
    private final JobRepository jobRepo;
    private final PortfolioItemRepository portfolioRepo;

    public FreelancerHomeService(UserAccountRepository userRepo, FreelancerProfileRepository profileRepo, JobRepository jobRepo, PortfolioItemRepository portfolioRepo) {
        this.userRepo = userRepo; this.profileRepo = profileRepo; this.jobRepo = jobRepo; this.portfolioRepo = portfolioRepo;
    }

    public HomeDto getHome(Long userId) {
        UserAccount user = userRepo.findById(userId).orElseThrow(() -> new IllegalArgumentException("user not found"));
        FreelancerProfile profile = profileRepo.findByUser(user).orElse(null);
        List<Job> recentAssigned = jobRepo.findTop5ByAssignedFreelancerOrderByCreatedAtDesc(user);
        List<Job> recommended = jobRepo.findTop5ByStatusAndAssignedFreelancerIsNullOrderByCreatedAtDesc(JobStatus.OPEN);
        long assignedCount = jobRepo.countByAssignedFreelancer(user);
        long completedCount = recentAssigned.stream().filter(j -> j.getStatus() == JobStatus.COMPLETED).count();
        long portfolioCount = portfolioRepo.countByFreelancer(user);
        var portfolioItems = portfolioRepo.findTop6ByFreelancerOrderByCreatedAtDesc(user);
        long totalBudgetCents = recentAssigned.stream().mapToLong(Job::getBudgetCents).sum();
        Set<String> distinctClients = recentAssigned.stream()
                .map(Job::getClientOwner)
                .filter(c -> c != null)
                .map(UserAccount::getEmail)
                .collect(Collectors.toSet());
        int successPercent = assignedCount == 0 ? 0 : (int) Math.round((completedCount * 100.0) / assignedCount);
        return HomeDto.of(user, profile, assignedCount, completedCount, portfolioCount, recentAssigned, recommended, portfolioItems, distinctClients.size(), totalBudgetCents, successPercent);
    }

    public record HomeDto(Long userId, String email,
                          String displayName, String professionalTitle, String skillsCsv, String bio, String imageUrl,
                          long assignedCount, long completedCount, long portfolioCount,
                          long distinctClients, long totalBudgetCents, int successPercent,
                          List<JobDto> recentAssignedJobs,
                          List<JobDto> recommendedJobs,
                          List<PortfolioDto> portfolioItems) {
        static HomeDto of(UserAccount u, FreelancerProfile p, long assignedCount, long completedCount, long portfolioCount,
                          List<Job> recentAssigned, List<Job> recommended, List<PortfolioItem> portfolio,
                          long distinctClients, long totalBudgetCents, int successPercent) {
            return new HomeDto(
                    u.getId(), u.getEmail(),
                    p != null ? p.getDisplayName() : null,
                    p != null ? p.getProfessionalTitle() : null,
                    p != null ? p.getSkillsCsv() : null,
                    p != null ? p.getBio() : null,
                    p != null ? p.getImageUrl() : null,
                    assignedCount, completedCount, portfolioCount,
                    distinctClients, totalBudgetCents, successPercent,
                    recentAssigned.stream().map(JobDto::from).collect(Collectors.toList()),
                    recommended.stream().map(JobDto::from).collect(Collectors.toList()),
                    portfolio.stream().map(PortfolioDto::from).collect(Collectors.toList())
            );
        }
    }

    public record JobDto(Long id, String title, long budgetCents, String status, String clientEmail) {
        static JobDto from(Job j) {
            return new JobDto(j.getId(), j.getTitle(), j.getBudgetCents(), j.getStatus().name(), j.getClientOwner()!=null? j.getClientOwner().getEmail():null);
        }
    }

    public record PortfolioDto(Long id, String title, String imageUrl) {
        static PortfolioDto from(PortfolioItem p) { return new PortfolioDto(p.getId(), p.getTitle(), p.getImageUrl()); }
    }
}
