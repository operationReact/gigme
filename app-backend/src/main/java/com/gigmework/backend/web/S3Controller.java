package com.gigmework.backend.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import java.time.Duration;
import java.net.URL;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.regions.Region;

@RestController
public class S3Controller {
    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    public S3Controller(S3Client s3Client, AwsCredentialsProvider credentialsProvider) {
        this.s3Client = s3Client;
        this.s3Presigner = S3Presigner.builder()
            .region(Region.US_EAST_1) // Or inject region if configurable
            .credentialsProvider(credentialsProvider)
            .build();
    }

    @GetMapping("/api/s3/presign-upload")
    public ResponseEntity<String> getPresignedUploadUrl(@RequestParam String key) {
        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();
        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .putObjectRequest(putObjectRequest)
                .build();
        URL presignedUrl = s3Presigner.presignPutObject(presignRequest).url();
        return ResponseEntity.ok(presignedUrl.toString());
    }

    @GetMapping("/api/s3/presign-download")
    public ResponseEntity<String> getPresignedDownloadUrl(@RequestParam String key) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();
        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .getObjectRequest(getObjectRequest)
                .build();
        URL presignedUrl = s3Presigner.presignGetObject(presignRequest).url();
        return ResponseEntity.ok(presignedUrl.toString());
    }

    @GetMapping("/api/s3/buckets")
    public ResponseEntity<?> listBuckets() {
        try {
            var buckets = s3Client.listBuckets().buckets();
            var bucketNames = buckets.stream().map(b -> b.name()).toList();
            return ResponseEntity.ok(bucketNames);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error listing buckets: " + e.getMessage());
        }
    }
}
