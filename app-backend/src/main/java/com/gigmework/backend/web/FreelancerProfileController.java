package com.gigmework.backend.web;

import com.gigmework.backend.domain.FreelancerProfile;
import com.gigmework.backend.service.FreelancerProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/freelancers")
public class FreelancerProfileController {
    private final FreelancerProfileService service;

    public FreelancerProfileController(FreelancerProfileService service) { this.service = service; }

    @GetMapping("/{userId}/profile")
    public ResponseEntity<?> get(@PathVariable Long userId) {
        return service.getByUser(userId)
                .<ResponseEntity<?>>map(fp -> ResponseEntity.ok(FreelancerProfileDto.from(fp)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/{userId}/profile")
    public ResponseEntity<?> upsert(@PathVariable Long userId, @RequestBody UpsertFreelancerProfile body) {
        try {
            FreelancerProfile fp = service.createOrUpdate(userId, body.displayName(), body.professionalTitle(), body.bio(), body.skillsCsv());
            return ResponseEntity.ok(FreelancerProfileDto.from(fp));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    public record UpsertFreelancerProfile(String displayName, String professionalTitle, String bio, String skillsCsv) {}
    public record FreelancerProfileDto(Long id, Long userId, String displayName, String professionalTitle, String bio, String skillsCsv) {
        static FreelancerProfileDto from(FreelancerProfile fp) {
            return new FreelancerProfileDto(fp.getId(), fp.getUser().getId(), fp.getDisplayName(), fp.getProfessionalTitle(), fp.getBio(), fp.getSkillsCsv());
        }
    }
}

