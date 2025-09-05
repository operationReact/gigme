package com.gigmework.backend.config;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.repo.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner seed(UserAccountRepository users,
                           FreelancerProfileRepository freelancers,
                           ClientProfileRepository clients,
                           JobRepository jobs,
                           PortfolioItemRepository portfolioItems) {
        return args -> {
            if (users.count() == 0) {
                UserAccount client1 = users.save(new UserAccount("client@example.com", "password", UserRole.CLIENT));
                UserAccount client2 = users.save(new UserAccount("acme@example.com", "password", UserRole.CLIENT));
                UserAccount free1 = users.save(new UserAccount("1@1.com", "password", UserRole.FREELANCER));
                UserAccount free2 = users.save(new UserAccount("designer@example.com", "password", UserRole.FREELANCER));

                clients.save(new ClientProfile(client1, "Client One", "https://client.one", "Early adopter client."));
                clients.save(new ClientProfile(client2, "Acme Corp", "https://acme.test", "Acme hires for diverse micro-projects."));

                freelancers.save(new FreelancerProfile(free1, "Satya Varma Lutukurthi", "Public FIgure", "Building robust Flutter & Spring apps.", "Content Creator,Youtuber,REST,PostgreSQL", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/3_1756664248816_thestayabro.jpg"));
                freelancers.save(new FreelancerProfile(free2, "Creative Designer", "UI/UX Designer", "Designing intuitive user experiences.", "Figma,UX,Branding", "https://randomuser.me/api/portraits/women/2.jpg"));

                Job j1 = new Job("Build landing page animation", "Need a smooth hero animation in Flutter Web.", client1, 150_00L);
                Job j2 = new Job("Optimize API performance", "Profiling and improving endpoints latency.", client1, 500_00L);
                Job j3 = new Job("Design new brand kit", "Logo refresh and color palette.", client2, 900_00L);
                Job j4 = new Job("Create onboarding flow", "Multi-step onboarding for mobile app.", client2, 400_00L);
                Job j5 = new Job("Implement analytics dashboard", "Charts & KPIs dashboard.", client1, 1200_00L);

                // Assign some
                j2.assignFreelancer(free1); // in progress
                j3.assignFreelancer(free2); j3.markCompleted();
                j5.assignFreelancer(free1); // in progress

                jobs.save(j1);
                jobs.save(j2);
                jobs.save(j3);
                jobs.save(j4);
                jobs.save(j5);


                portfolioItems.save(new PortfolioItem(free1, "SaaS Dashboard", "Admin analytics interface", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/3_1757003279405_thestayabro.jpg", MediaType.IMAGE, 204800L, 400, 300, null, null));
                portfolioItems.save(new PortfolioItem(free1, "E‑commerce App", "Mobile storefront prototype", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/3_1757003279405_thestayabro.jpg", MediaType.IMAGE, 205000L, 400, 300, null, null));
                portfolioItems.save(new PortfolioItem(free1, "Chat Module", "Realtime messaging UI", "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4", MediaType.VIDEO, 1048576L, null, null, 60, "https://img.youtube.com/vi/YE7VzlLtp-4/0.jpg"));
                portfolioItems.save(new PortfolioItem(free2, "Brand Kit", "Logo & typography system", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/3_1757003279405_thestayabro.jpg", MediaType.IMAGE, 203000L, 400, 300, null, null));
                portfolioItems.save(new PortfolioItem(free2, "Marketing Site", "Landing page redesign", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/99666.pdf", MediaType.DOCUMENT, 153600L, null, null, null, null));
            }
        };
    }
}
