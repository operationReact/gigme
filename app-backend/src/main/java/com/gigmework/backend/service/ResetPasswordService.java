package com.gigmework.backend.service;

import com.gigmework.backend.domain.ResetPasswordToken;
import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.repo.ResetPasswordTokenRepository;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.regex.Pattern;

@Service
@Transactional
public class ResetPasswordService {
    private final UserAccountRepository userRepo;
    private final ResetPasswordTokenRepository tokenRepo;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    private static final Pattern LOWER = Pattern.compile("[a-z]");
    private static final Pattern UPPER = Pattern.compile("[A-Z]");
    private static final Pattern DIGIT = Pattern.compile("[0-9]");
    private static final Pattern SYMBOL = Pattern.compile("[^A-Za-z0-9]");

    public ResetPasswordService(UserAccountRepository userRepo, ResetPasswordTokenRepository tokenRepo) {
        this.userRepo = userRepo; this.tokenRepo = tokenRepo;
    }

    /** Create a reset token for an email if it exists. Always return Optional token to caller for demo (would email in production). */
    public Optional<ResetPasswordToken> createResetToken(String email) {
        if(email==null || email.isBlank()) throw new IllegalArgumentException("email required");
        return userRepo.findByEmailIgnoreCase(email.toLowerCase()).map(u -> tokenRepo.save(ResetPasswordToken.create(u, 30))); // 30 min
    }

    /** Reset password using token. Returns user id on success. */
    public Long resetPassword(String token, String newPassword){
        if(token==null || token.isBlank()) throw new IllegalArgumentException("token required");
        if(newPassword==null) throw new IllegalArgumentException("password required");
        validateStrength(newPassword);
        ResetPasswordToken rpt = tokenRepo.findByToken(token).orElseThrow(() -> new IllegalArgumentException("invalid token"));
        if(rpt.isUsed() || rpt.isExpired()) throw new IllegalStateException("token invalid or expired");
        UserAccount user = rpt.getUser();
        user.setPassword(encoder.encode(newPassword));
        rpt.markUsed();
        return user.getId();
    }

    private void validateStrength(String p){
        if(p.length() < 8) throw new IllegalArgumentException("weak password");
        int criteria=0; if(LOWER.matcher(p).find()) criteria++; if(UPPER.matcher(p).find()) criteria++; if(DIGIT.matcher(p).find()) criteria++; if(SYMBOL.matcher(p).find()) criteria++;
        if(criteria < 3) throw new IllegalArgumentException("weak password");
    }

    /** Optional cleanup method */
    public long purgeExpired(){ return tokenRepo.deleteByExpiresAtBefore(Instant.now()); }
}
