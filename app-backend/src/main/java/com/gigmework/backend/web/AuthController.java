package com.gigmework.backend.web;

import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.domain.UserRole;
import com.gigmework.backend.service.UserService;
import com.gigmework.backend.service.ResetPasswordService;
import com.gigmework.backend.service.MailService;
import com.gigmework.backend.service.RateLimiterService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserService userService;
    private final ResetPasswordService resetPasswordService;
    private final MailService mailService;
    private final RateLimiterService rateLimiter;

    public AuthController(UserService userService, ResetPasswordService resetPasswordService, MailService mailService, RateLimiterService rateLimiter) { this.userService = userService; this.resetPasswordService = resetPasswordService; this.mailService = mailService; this.rateLimiter = rateLimiter; }

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
        return userService.authenticate(body.email(), body.password())
                .<ResponseEntity<?>>map(u -> ResponseEntity.ok(AuthUser.from(u)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "invalid credentials")));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgot(@RequestBody ForgotPasswordRequest body){
        try {
            final String email = body.email();
            if(!rateLimiter.allow(email == null? "": email.toLowerCase())) {
                // silently accept but skip generation to avoid enumeration & abuse
                return ResponseEntity.ok(Map.of("status","ok"));
            }
            var opt = resetPasswordService.createResetToken(email);
            opt.ifPresent(t -> mailService.sendPasswordResetEmail(t.getUser().getEmail(), t.getToken()));
            return ResponseEntity.ok(Map.of("status","ok"));
        } catch (IllegalArgumentException ex){
            return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage()));
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> reset(@RequestBody ResetPasswordRequest body){
        try {
            Long userId = resetPasswordService.resetPassword(body.token(), body.newPassword());
            return ResponseEntity.ok(Map.of("status","ok","userId", userId));
        } catch (IllegalArgumentException | IllegalStateException ex){
            return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage()));
        }
    }

    public record RegisterRequest(String email, String password, UserRole role) {}
    public record LoginRequest(String email, String password) {}
    public record ForgotPasswordRequest(String email) {}
    public record ResetPasswordRequest(String token, String newPassword) {}
    public record AuthUser(Long id, String email, UserRole role, boolean hasFreelancerProfile, boolean hasClientProfile) {
        static AuthUser from(UserAccount ua) {
            return new AuthUser(ua.getId(), ua.getEmail(), ua.getRole(), ua.hasFreelancerProfile(), ua.hasClientProfile());
        }
    }
}
