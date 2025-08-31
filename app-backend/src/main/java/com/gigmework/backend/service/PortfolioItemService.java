package com.gigmework.backend.service;

import com.gigmework.backend.domain.MediaType;
import com.gigmework.backend.domain.PortfolioItem;
import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.repo.PortfolioItemRepository;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PortfolioItemService {
    private final PortfolioItemRepository portfolioItemRepository;
    private final UserAccountRepository userAccountRepository;

    public PortfolioItemService(PortfolioItemRepository portfolioItemRepository, UserAccountRepository userAccountRepository) {
        this.portfolioItemRepository = portfolioItemRepository;
        this.userAccountRepository = userAccountRepository;
    }

    public PortfolioItem createPortfolioItem(Long freelancerId, String title, String description, String fileUrl, MediaType mediaType) {
        UserAccount freelancer = userAccountRepository.findById(freelancerId).orElseThrow();
        PortfolioItem item = new PortfolioItem(freelancer, title, description, fileUrl, mediaType);
        return portfolioItemRepository.save(item);
    }

    public List<PortfolioItem> getPortfolioItems(Long freelancerId, MediaType mediaType) {
        UserAccount freelancer = userAccountRepository.findById(freelancerId).orElseThrow();
        if (mediaType == null) {
            return portfolioItemRepository.findTop6ByFreelancerOrderByCreatedAtDesc(freelancer);
        } else {
            return portfolioItemRepository.findByFreelancerAndMediaTypeOrderByCreatedAtDesc(freelancer, mediaType);
        }
    }
}

