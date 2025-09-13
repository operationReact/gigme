package com.gigmework.backend.config;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.repo.*;
import com.gigmework.backend.models.ContactLink;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner seed(UserAccountRepository users,
                           FreelancerProfileRepository freelancers,
                           ClientProfileRepository clients,
                           JobRepository jobs,
                           PortfolioItemRepository portfolioItems,
                           ContactLinkRepository contactLinks) {
        return args -> {
            if (users.count() == 0) {
                UserAccount client1 = users.save(new UserAccount("client@example.com", "password", UserRole.CLIENT));
                UserAccount client2 = users.save(new UserAccount("acme@example.com", "password", UserRole.CLIENT));
                UserAccount free1 = users.save(new UserAccount("1@1.com", "password", UserRole.FREELANCER));
                UserAccount free2 = users.save(new UserAccount("designer@example.com", "password", UserRole.FREELANCER));

                clients.save(new ClientProfile(client1, "Client One", "https://client.one", "Early adopter client."));
                clients.save(new ClientProfile(client2, "Acme Corp", "https://acme.test", "Acme hires for diverse micro-projects."));

                freelancers.save(new FreelancerProfile(
                        free1,
                        "Satya Varma Lutukurthi",
                        "Public FIgure",
                        "Building robust Flutter & Spring apps.",
                        "Content Creator,Youtuber,REST,PostgreSQL",
                        "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/3_1756664248816_thestayabro.jpg",
                        "Remote / Worldwide",
                        "1@1.com",
                        null,
                        "https://satya.example.com",
                        "https://linkedin.com/in/satya",
                        "https://github.com/satya",
                        6000,
                        "USD",
                        true
                ));
                freelancers.save(new FreelancerProfile(
                        free2,
                        "Creative Designer",
                        "UI/UX Designer",
                        "Designing intuitive user experiences.",
                        "Figma,UX,Branding",
                        "https://randomuser.me/api/portraits/women/2.jpg",
                        "Berlin, DE",
                        "designer@example.com",
                        null,
                        "https://designer.example.com",
                        "https://linkedin.com/in/designer",
                        "https://github.com/designer",
                        8500,
                        "EUR",
                        true
                ));

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
                portfolioItems.save(new PortfolioItem(free1, "Chat Module", "Realtime messaging UI", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/Bihar+tree+scam.mov", MediaType.VIDEO, 1048576L, null, null, 60, "https://img.youtube.com/vi/YE7VzlLtp-4/0.jpg"));
                portfolioItems.save(new PortfolioItem(free1, "Brand Kit", "Logo & typography system", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/3_1757003279405_thestayabro.jpg", MediaType.IMAGE, 203000L, 400, 300, null, null));
                portfolioItems.save(new PortfolioItem(free1, "Marketing Site", "Landing page redesign", "https://gigmes3dev.s3.us-east-1.amazonaws.com/images/99666.pdf", MediaType.DOCUMENT, 153600L, null, null, null, null));

                // Seed contact links for the first freelancer (userId = free1.getId())
                ContactLink l1 = new ContactLink();
                l1.setUserId(free1.getId());
                l1.setLabel("Youtube");
                l1.setUrl("https://www.youtube.com/@thesatyabro");
                l1.setKind("website");
                l1.setSortOrder(1);

                ContactLink l2 = new ContactLink();
                l2.setUserId(free1.getId());
                l2.setLabel("Instagram");
                l2.setUrl("https://www.instagram.com/thesatyabro/");
                l2.setKind("linkedin");
                l2.setSortOrder(2);

                ContactLink l3 = new ContactLink();
                l3.setUserId(free1.getId());
                l3.setLabel("GigMeWork");
                l3.setUrl("https://github.com/satya");
                l3.setKind("github");
                l3.setSortOrder(3);

                contactLinks.save(l1);
                contactLinks.save(l2);
                contactLinks.save(l3);
            }

            // Large synthetic freelancer seeding (idempotent-ish): only if total freelancers < 10k
            long freelancerCount = freelancers.count();
            final int TARGET = 10_000;
            if (freelancerCount < TARGET) {
                int toCreate = (int)(TARGET - freelancerCount);
                String[] titles = {"Mobile Dev", "Backend Engineer", "UI/UX Designer", "Full‑Stack Dev", "Data Engineer", "Cloud Architect"};
                String[] skillsSets = {"Flutter,Dart,Firebase", "Spring Boot,PostgreSQL,REST", "Figma,Wireframes,User Research", "React,TypeScript,Node", "SQL,ETL,Pipelines", "AWS,Terraform,CI/CD"};
                int batchSize = 500;
                List<UserAccount> userBatch = new ArrayList<>(batchSize);
                List<FreelancerProfile> profileBatch = new ArrayList<>(batchSize);
                for (int i = 0; i < toCreate; i++) {
                    long idx = freelancerCount + i + 1;
                    String email = "auto" + idx + "@example.dev";
                    UserAccount ua = new UserAccount(email, "password", UserRole.FREELANCER);
                    userBatch.add(ua);
                    int pick = (int)(idx % titles.length);
                    profileBatch.add(new FreelancerProfile(
                            ua,
                            "User " + idx,
                            titles[pick],
                            "Enthusiastic professional #" + idx + " delivering quality.",
                            skillsSets[pick],
                            null,
                            "Remote",
                            email,
                            null,
                            null,
                            null,
                            null,
                            5000 + (int)(idx % 4000),
                            "USD",
                            true
                    ));
                    if ((i + 1) % batchSize == 0 || i == toCreate - 1) {
                        users.saveAll(userBatch); // ensures user ids
                        freelancers.saveAll(profileBatch);
                        userBatch.clear();
                        profileBatch.clear();
                    }
                }
            }
        };
    }
}
