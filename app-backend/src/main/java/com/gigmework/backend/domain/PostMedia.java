package com.gigmework.backend.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "post_media")
public class PostMedia {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id")
    private Post post;

    @Column(nullable = false, length = 500)
    private String url;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MediaType mediaType;

    @Column(name = "order_index", nullable = false)
    private int orderIndex;

    @Column(name = "width")
    private Integer width;
    @Column(name = "height")
    private Integer height;
    @Column(name = "duration_seconds")
    private Integer durationSeconds;
    @Column(name = "thumbnail_url", length = 500)
    private String thumbnailUrl;

    protected PostMedia() {}
    public PostMedia(Post post, String url, MediaType mediaType, int orderIndex, Integer width, Integer height, Integer durationSeconds, String thumbnailUrl) {
        this.post = post; this.url = url; this.mediaType = mediaType; this.orderIndex = orderIndex; this.width = width; this.height = height; this.durationSeconds = durationSeconds; this.thumbnailUrl = thumbnailUrl;
    }
    public Long getId() { return id; }
    public Post getPost() { return post; }
    public String getUrl() { return url; }
    public MediaType getMediaType() { return mediaType; }
    public int getOrderIndex() { return orderIndex; }
    public Integer getWidth() { return width; }
    public Integer getHeight() { return height; }
    public Integer getDurationSeconds() { return durationSeconds; }
    public String getThumbnailUrl() { return thumbnailUrl; }
}

