package com.gigmework.backend.service;

import com.gigmework.backend.models.ContactLink;
import com.gigmework.backend.repo.ContactLinkRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ContactLinkService {

    @Autowired
    private ContactLinkRepository contactLinkRepository;

    public List<ContactLink> getContactLinksByUserId(Long userId) {
        return contactLinkRepository.findByUserId(userId);
    }

    public ContactLink createContactLink(ContactLink contactLink) {
        return contactLinkRepository.save(contactLink);
    }

    public ContactLink updateContactLink(Long id, ContactLink updatedContactLink) {
        Optional<ContactLink> existingLink = contactLinkRepository.findById(id);
        if (existingLink.isPresent()) {
            ContactLink link = existingLink.get();
            link.setLabel(updatedContactLink.getLabel());
            link.setUrl(updatedContactLink.getUrl());
            link.setKind(updatedContactLink.getKind());
            link.setSortOrder(updatedContactLink.getSortOrder());
            return contactLinkRepository.save(link);
        } else {
            throw new RuntimeException("Contact link not found");
        }
    }

    public void deleteContactLink(Long id) {
        contactLinkRepository.deleteById(id);
    }
}
