package com.gigmework.backend.web;

import com.gigmework.backend.domain.MediaType;
import com.gigmework.backend.domain.PortfolioItem;
import com.gigmework.backend.service.PortfolioItemService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/portfolio-items")
public class PortfolioItemController {
    private final PortfolioItemService service;

    public PortfolioItemController(PortfolioItemService service) {
        this.service = service;
    }

    @PostMapping("")
    public ResponseEntity<PortfolioItem> createPortfolioItem(@RequestBody CreatePortfolioItemRequest request) {
        PortfolioItem item = service.createPortfolioItem(
                request.freelancerId(),
                request.title(),
                request.description(),
                request.fileUrl(),
                request.mediaType()
        );
        return ResponseEntity.ok(item);
    }

    @GetMapping("")
    public ResponseEntity<List<PortfolioItem>> getPortfolioItems(
            @RequestParam Long freelancerId,
            @RequestParam(required = false) MediaType mediaType
    ) {
        List<PortfolioItem> items = service.getPortfolioItems(freelancerId, mediaType);
        return ResponseEntity.ok(items);
    }

    public record CreatePortfolioItemRequest(Long freelancerId, String title, String description, String fileUrl, MediaType mediaType) {}
}

