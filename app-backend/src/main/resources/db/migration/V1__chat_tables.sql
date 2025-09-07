/* Copilot: SQL migration for chat tables (Postgres).
- conversations(id PK, is_group bool, title text, created_at timestamptz default now())
- conversation_participants(conversation_id fk, user_id bigint, role text default 'member', last_read_msg_id bigint, joined_at timestamptz default now(), PK(conversation_id,user_id))
- messages(id PK, conversation_id fk, sender_user_id bigint, body text null, attachment_url text null, attachment_mime text null, kind text default 'text', created_at timestamptz default now())
- Indexes: messages(conv_id, created_at desc), participants(conv_id), participants(user_id)
- Add FKs with cascade delete on conv->messages and conv->participants
*/

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id BIGSERIAL PRIMARY KEY,
    is_group BOOLEAN NOT NULL DEFAULT FALSE,
    title TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create conversation participants table
CREATE TABLE IF NOT EXISTS conversation_participants (
    conversation_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member',
    last_read_msg_id BIGINT,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id),
    CONSTRAINT fk_participant_conversation
        FOREIGN KEY (conversation_id)
        REFERENCES conversations(id)
        ON DELETE CASCADE
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    sender_user_id BIGINT NOT NULL,
    body TEXT,
    attachment_url TEXT,
    attachment_mime TEXT,
    kind TEXT NOT NULL DEFAULT 'text',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_message_conversation
        FOREIGN KEY (conversation_id)
        REFERENCES conversations(id)
        ON DELETE CASCADE
);

-- Indexes to speed up queries
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created_at
    ON messages (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_participants_conversation
    ON conversation_participants (conversation_id);

CREATE INDEX IF NOT EXISTS idx_participants_user
    ON conversation_participants (user_id);

