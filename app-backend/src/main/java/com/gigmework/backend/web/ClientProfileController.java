package com.gigmework.backend.web;

import com.gigmework.backend.domain.ClientProfile;
import com.gigmework.backend.service.ClientProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/clients")
public class ClientProfileController {
    private final ClientProfileService service;

    public ClientProfileController(ClientProfileService service) { this.service = service; }

    @GetMapping("/{userId}/profile")
    public ResponseEntity<?> get(@PathVariable Long userId) {
        return service.getByUser(userId)
                .<ResponseEntity<?>>map(cp -> ResponseEntity.ok(ClientProfileDto.from(cp)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/{userId}/profile")
    public ResponseEntity<?> upsert(@PathVariable Long userId, @RequestBody UpsertClientProfile body) {
        try {
            ClientProfile cp = service.createOrUpdate(userId, body.companyName(), body.website(), body.description());
            return ResponseEntity.ok(ClientProfileDto.from(cp));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    public record UpsertClientProfile(String companyName, String website, String description) {}
    public record ClientProfileDto(Long id, Long userId, String companyName, String website, String description) {
        static ClientProfileDto from(ClientProfile cp) {
            return new ClientProfileDto(cp.getId(), cp.getUser().getId(), cp.getCompanyName(), cp.getWebsite(), cp.getDescription());
        }
    }
}

