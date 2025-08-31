package com.gigmework.backend.web;

import com.gigmework.backend.domain.MediaType;
import com.gigmework.backend.domain.PortfolioItem;
import com.gigmework.backend.service.FreelancerHomeService.PortfolioDto;
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
                request.mediaType(),
                request.fileSize(),
                request.width(),
                request.height(),
                request.durationSeconds(),
                request.thumbnailUrl()
        );
        return ResponseEntity.ok(item);
    }

    @GetMapping("")
    public ResponseEntity<List<PortfolioDto>> getPortfolioItems(
            @RequestParam Long freelancerId,
            @RequestParam(required = false) MediaType mediaType
    ) {
        List<PortfolioItem> items = service.getPortfolioItems(freelancerId, mediaType);
        List<PortfolioDto> dtos = items.stream().map(PortfolioDto::from).toList();
        return ResponseEntity.ok(dtos);
    }

    public record CreatePortfolioItemRequest(
            Long freelancerId,
            String title,
            String description,
            String fileUrl,
            MediaType mediaType,
            Long fileSize,
            Integer width,
            Integer height,
            Integer durationSeconds,
            String thumbnailUrl
    ) {}
}
