package com.gigmework.backend.web;

import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.domain.UserRole;
import com.gigmework.backend.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserService userService;

    public AuthController(UserService userService) { this.userService = userService; }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest body) {
        try {
            UserAccount ua = userService.register(body.email(), body.password(), body.role());
            return ResponseEntity.status(HttpStatus.CREATED).body(AuthUser.from(ua));
        } catch (IllegalArgumentException | IllegalStateException ex) {
            return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest body) {
        return userService.findByEmail(body.email())
                .filter(u -> u.getPassword().equals(body.password())) // DEMO ONLY: plain password check
                .<ResponseEntity<?>>map(u -> ResponseEntity.ok(AuthUser.from(u)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "invalid credentials")));
    }

    public record RegisterRequest(String email, String password, UserRole role) {}
    public record LoginRequest(String email, String password) {}
    public record AuthUser(Long id, String email, UserRole role, boolean hasFreelancerProfile, boolean hasClientProfile) {
        static AuthUser from(UserAccount ua) {
            return new AuthUser(ua.getId(), ua.getEmail(), ua.getRole(), ua.hasFreelancerProfile(), ua.hasClientProfile());
        }
    }
}

