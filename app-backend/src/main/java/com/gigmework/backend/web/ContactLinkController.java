package com.gigmework.backend.web;

import com.gigmework.backend.models.ContactLink;
import com.gigmework.backend.service.ContactLinkService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contact-links")
public class ContactLinkController {

    @Autowired
    private ContactLinkService contactLinkService;

    @GetMapping
    public ResponseEntity<List<ContactLink>> getContactLinks(@RequestParam("userId") Long userId) {
        List<ContactLink> links = contactLinkService.getContactLinksByUserId(userId);
        return ResponseEntity.ok(links);
    }

       // Public, read-only endpoint for the shareable card
    @GetMapping("/public")
    public ResponseEntity<List<ContactLink>> getContactLinksPublic(@RequestParam("userId") Long userId) {
        List<ContactLink> links = contactLinkService.getContactLinksByUserId(userId);
        return ResponseEntity.ok(links);
    }

    @PostMapping
    public ResponseEntity<ContactLink> createContactLink(@RequestBody ContactLink contactLink) {
        ContactLink createdLink = contactLinkService.createContactLink(contactLink);
        return ResponseEntity.status(201).body(createdLink);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ContactLink> updateContactLink(@PathVariable Long id, @RequestBody ContactLink contactLink) {
        ContactLink updatedLink = contactLinkService.updateContactLink(id, contactLink);
        return ResponseEntity.ok(updatedLink);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteContactLink(@PathVariable Long id) {
        contactLinkService.deleteContactLink(id);
        return ResponseEntity.noContent().build();
    }
}
