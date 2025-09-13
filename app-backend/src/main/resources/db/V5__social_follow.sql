-- Social follow table for creator relationships
CREATE TABLE IF NOT EXISTS social_follow (
    id BIGSERIAL PRIMARY KEY,
    follower_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id   BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(follower_id, target_id)
);
CREATE INDEX IF NOT EXISTS idx_social_follow_follower ON social_follow(follower_id);
CREATE INDEX IF NOT EXISTS idx_social_follow_target ON social_follow(target_id);

