package com.gigmework.backend.web;

import com.gigmework.backend.domain.MediaType;
import com.gigmework.backend.domain.PortfolioItem;
import com.gigmework.backend.service.FreelancerHomeService.PortfolioDto;
import com.gigmework.backend.service.PortfolioItemService;
import com.gigmework.backend.service.S3Service;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/portfolio-items")
public class PortfolioItemController {
    private final PortfolioItemService service;
    private final S3Service s3Service;

    public PortfolioItemController(PortfolioItemService service, S3Service s3Service) {
        this.service = service;
        this.s3Service = s3Service;
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

    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public ResponseEntity<PortfolioItem> uploadPortfolioItem(
            @RequestParam Long freelancerId,
            @RequestParam String title,
            @RequestParam(required = false) String description,
            @RequestParam("file") MultipartFile file,
            @RequestParam MediaType mediaType
    ) throws Exception {
        // Validate file type
        if (!isValidFileType(file, mediaType)) {
            return ResponseEntity.badRequest().build();
        }
        // Upload to S3
        String folder = mediaType.name().toLowerCase() + "s";
        String fileUrl = s3Service.uploadFile(file, folder);
        Long fileSize = file.getSize();
        Integer width = null, height = null, durationSeconds = null;
        String thumbnailUrl = null;
        // Optionally: extract width/height for images, duration for videos, etc.
        PortfolioItem item = service.createPortfolioItem(
                freelancerId, title, description, fileUrl, mediaType, fileSize, width, height, durationSeconds, thumbnailUrl
        );
        return ResponseEntity.ok(item);
    }

    private boolean isValidFileType(MultipartFile file, MediaType mediaType) {
        String contentType = file.getContentType();
        String filename = file.getOriginalFilename();
        if (contentType == null || filename == null) return false;
        Set<String> imageTypes = Set.of("image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp");
        Set<String> videoTypes = Set.of("video/mp4", "video/quicktime", "video/x-msvideo", "video/x-matroska");
        Set<String> docTypes = Set.of("application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        switch (mediaType) {
            case IMAGE -> {
                return imageTypes.contains(contentType);
            }
            case VIDEO -> {
                return videoTypes.contains(contentType);
            }
            case DOCUMENT -> {
                return docTypes.contains(contentType);
            }
            default -> {
                return false;
            }
        }
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
