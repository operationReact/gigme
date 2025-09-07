package com.gigmework.backend.util;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URL;
import java.text.ParseException;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Objects;

/**
 * Verifies RS256 JWTs issued by AWS Cognito using the user pool JWKS.
 * Fetches and caches the JWKS for 10 minutes.
 */
@Component
public class CognitoJwtVerifier {

    private final String region;
    private final String userPoolId;
    private volatile JWKSet cachedJwkSet;
    private volatile Instant jwksFetchedAt;

    private static final Duration JWKS_TTL = Duration.ofMinutes(10);
    private static final Duration CLOCK_SKEW = Duration.ofSeconds(60);

    public CognitoJwtVerifier(
            @Value("${cognito.region}") String region,
            @Value("${cognito.userPoolId}") String userPoolId
    ) {
        this.region = Objects.requireNonNull(region, "cognito.region is required");
        this.userPoolId = Objects.requireNonNull(userPoolId, "cognito.userPoolId is required");
    }

    public JWTClaimsSet verify(String token) throws ParseException, JOSEException, IOException {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("JWT token is required");
        }

        SignedJWT signedJWT = SignedJWT.parse(token);
        JWSHeader header = signedJWT.getHeader();

        if (!JWSAlgorithm.RS256.equals(header.getAlgorithm())) {
            throw new JOSEException("Unsupported JWS algorithm: " + header.getAlgorithm());
        }

        // Ensure JWKS is loaded and fresh
        JWKSet jwkSet = getFreshJwkSet();

        // Find the public key by kid
        String kid = header.getKeyID();
        if (kid == null || kid.isBlank()) {
            throw new JOSEException("Missing key ID (kid) in token header");
        }
        JWK matchedJwk = jwkSet.getKeys().stream()
                .filter(jwk -> kid.equals(jwk.getKeyID()) && jwk instanceof RSAKey)
                .findFirst()
                .orElseThrow(() -> new JOSEException("No matching JWK for kid: " + kid));

        RSAKey rsaKey = (RSAKey) matchedJwk;
        RSASSAVerifier verifier = new RSASSAVerifier(rsaKey);

        boolean signatureValid = signedJWT.verify(verifier);
        if (!signatureValid) {
            throw new JOSEException("Invalid JWT signature");
        }

        JWTClaimsSet claims = signedJWT.getJWTClaimsSet();
        validateTemporalClaims(claims);

        return claims;
    }

    private synchronized JWKSet getFreshJwkSet() throws IOException, ParseException {
        if (cachedJwkSet == null || jwksFetchedAt == null || Instant.now().isAfter(jwksFetchedAt.plus(JWKS_TTL))) {
            String url = String.format("https://cognito-idp.%s.amazonaws.com/%s/.well-known/jwks.json", region, userPoolId);
            cachedJwkSet = JWKSet.load(new URL(url));
            jwksFetchedAt = Instant.now();
        }
        return cachedJwkSet;
    }

    private void validateTemporalClaims(JWTClaimsSet claims) throws JOSEException {
        Instant now = Instant.now();
        Date exp = claims.getExpirationTime();
        if (exp == null || now.minus(CLOCK_SKEW).isAfter(exp.toInstant())) {
            throw new JOSEException("JWT is expired");
        }
        Date nbf = claims.getNotBeforeTime();
        if (nbf != null && now.plus(CLOCK_SKEW).isBefore(nbf.toInstant())) {
            throw new JOSEException("JWT not valid yet");
        }
    }
}
