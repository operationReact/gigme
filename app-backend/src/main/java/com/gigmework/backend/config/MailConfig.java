package com.gigmework.backend.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.util.Arrays;

/**
 * Provides a no-op JavaMailSender when no real mail sender is configured.
 * This prevents startup failures in dev / test environments where SMTP is absent.
 */
@Configuration
public class MailConfig {

    @Bean
    @ConditionalOnMissingBean(JavaMailSender.class)
    public JavaMailSender javaMailSender() {
        return new NoOpMailSender();
    }

    static class NoOpMailSender extends JavaMailSenderImpl {
        private static final Logger log = LoggerFactory.getLogger(NoOpMailSender.class);
        @Override
        public void send(SimpleMailMessage simpleMessage) {
            if(simpleMessage == null) return;
            log.info("[NO-OP MAIL] to={} subject='{}' (body omitted)", Arrays.toString(simpleMessage.getTo()), simpleMessage.getSubject());
        }
        @Override
        public void send(SimpleMailMessage... simpleMessages) {
            if(simpleMessages == null) return;
            for(SimpleMailMessage m : simpleMessages) send(m);
        }
    }
}

