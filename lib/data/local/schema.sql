
-- Mamadera Database Schema
-- Version: 5
-- Source : lib/data/local/app_db.dart (BabyProfiles + TrackingEvents + ReminderDismissals)
-- Changelog v5: Added `subtype` column for typed event subtype persistence (FeedingSubtype, HealthSubtype)

-- ── Baby Profiles ────────────────────────────────────────────────

CREATE TABLE baby_profiles (
    id          TEXT PRIMARY KEY NOT NULL,         -- UUID for the baby profile
    name        TEXT               NOT NULL,       -- Display name of the baby
    birth_date  INTEGER            NOT NULL,       -- Unix timestamp (milliseconds) for drift compatibility
    is_active   BOOLEAN DEFAULT 0 NOT NULL         -- Whether this is the currently active baby
);

-- ── Tracking Events ────────────────────────────────────────────────

CREATE TABLE tracking_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    type        TEXT                              NOT NULL,
    timestamp   TIMESTAMP                         NOT NULL,
    duration    REAL,                             -- en minutes (pour dodo et sein)
    subtype     TEXT,                             -- typed event subtype: 'sein'|'bib' for feeding, 'nettoyage_yeux'|'vitamine_d'|... for health
    notes       TEXT,                             -- encrypted user text only (no longer used for structured data)
    waste_type  TEXT,                             -- pipi, caca, les_deux (diaper events only)
    color       TEXT,                             -- couleur de la selle ou pipe-délimitée (pipi|caca)
    baby_id     TEXT                              -- nullable FK to baby_profiles(id), backward compatible
);

-- Migration v4 → v5: ALTER TABLE tracking_events ADD COLUMN subtype TEXT;

CREATE INDEX idx_tracking_events_type ON tracking_events(type);

CREATE INDEX idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type);


CREATE TABLE reminder_dismissals (
    item_id     TEXT PRIMARY KEY NOT NULL,         -- matches ReminderItem.id
    dismissed_at TIMESTAMP            NOT NULL     -- when the user last dismissed this reminder
);

