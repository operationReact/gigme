package com.gigmework.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class MailService {
    private static final Logger log = LoggerFactory.getLogger(MailService.class);
    private final JavaMailSender mailSender;

    @Value("${app.mail.from:no-reply@gigmework.local}")
    private String from;
    @Value("${app.frontend.url:http://localhost:3000}")
    private String frontendUrl;
    @Value("${app.reset.email.enabled:true}")
    private boolean emailEnabled;

    public MailService(JavaMailSender mailSender) { this.mailSender = mailSender; }

    public void sendPasswordResetEmail(String to, String token) {
        String link = frontendUrl + "/#/forgot-password?token=" + URLEncoder.encode(token, StandardCharsets.UTF_8) + "&email=" + URLEncoder.encode(to, StandardCharsets.UTF_8);
        if(!emailEnabled){
            log.info("[DEV] Password reset token for {}: {} (link: {})", to, token, link);
            return;
        }
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(to);
            msg.setSubject("Reset your GigMeWork password");
            msg.setText("We received a password reset request. Use the link below to set a new password (valid 30 minutes).\n\n" + link + "\n\nIf you did not request this, you can ignore this email.");
            mailSender.send(msg);
        } catch(Exception ex){
            log.warn("Failed to send password reset email to {}: {}", to, ex.getMessage());
            log.info("[FALLBACK] Password reset token for {}: {} (link: {})", to, token, link);
        }
    }
}
