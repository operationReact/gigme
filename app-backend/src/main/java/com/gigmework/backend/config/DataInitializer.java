package com.gigmework.backend.config;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.repo.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner seed(UserAccountRepository users, FreelancerProfileRepository freelancers, ClientProfileRepository clients, JobRepository jobs) {
        return args -> {
            if (users.count() == 0) {
                UserAccount client1 = users.save(new UserAccount("client@example.com", "password", UserRole.CLIENT));
                UserAccount client2 = users.save(new UserAccount("acme@example.com", "password", UserRole.CLIENT));
                UserAccount free1 = users.save(new UserAccount("dev@example.com", "password", UserRole.FREELANCER));
                UserAccount free2 = users.save(new UserAccount("designer@example.com", "password", UserRole.FREELANCER));

                clients.save(new ClientProfile(client1, "Client One", "https://client.one", "Early adopter client."));
                clients.save(new ClientProfile(client2, "Acme Corp", "https://acme.test", "Acme hires for diverse micro-projects."));

                freelancers.save(new FreelancerProfile(free1, "Dev Pro", "Full Stack Developer", "Building robust Flutter & Spring apps.", "Flutter,Spring,REST,PostgreSQL"));
                freelancers.save(new FreelancerProfile(free2, "Creative Designer", "UI/UX Designer", "Designing intuitive user experiences.", "Figma,UX,Branding"));

                jobs.save(new Job("Build landing page animation", "Need a smooth hero animation in Flutter Web.", client1));
                jobs.save(new Job("Optimize API performance", "Profiling and improving endpoints latency.", client1));
                jobs.save(new Job("Design new brand kit", "Logo refresh and color palette.", client2));
            }
        };
    }
}

