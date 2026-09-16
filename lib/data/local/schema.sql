-- Mamadera Database Schema
-- Version: 10
-- Generated reference from lib/data/local/app_db.dart — do not edit directly.
-- Source of truth is app_db.dart (Drift table definitions).
--
-- Changelog:
--   v5: Added `subtype` column for typed event subtype persistence
--   v6: Added `quantity` column (volume in ml for feedings, minutes for sleep)
--   v7: Migrated feeding subtype values 'sein'|'bib' → 'natural'|'artificial'
--   v8: Created `reminder_settings` for databases that predate v7 (declared in
--       app_db.dart since v7 but never created by onUpgrade)
--   v9: Added `texture` column (stool texture for diaper events, nullable)
--   v10: Created `custom_reminders` (reminders invented by the parent, linked
--        to a health care subtype)

-- ── Baby Profiles ────────────────────────────────────────────────

CREATE TABLE baby_profiles (
    id          TEXT PRIMARY KEY NOT NULL,         -- UUID for the baby profile
    name        TEXT               NOT NULL,       -- Display name of the baby
    birth_date  INTEGER            NOT NULL,       -- Unix timestamp (milliseconds) for drift compatibility
    is_active   BOOLEAN DEFAULT 1 NOT NULL         -- Whether this is the currently active baby
);

-- ── Tracking Events ────────────────────────────────────────────────

CREATE TABLE tracking_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    type        TEXT                              NOT NULL,   -- miam, caca, dodo, sante
    timestamp   TIMESTAMP                         NOT NULL,
    duration    REAL,                             -- en minutes (dodo, feeding)
    subtype     TEXT,                             -- typed event subtype: 'natural'|'artificial' for feeding, 'nettoyage_yeux'|'vitamine_d'|... for health
    notes       TEXT,                             -- encrypted user text only (no longer used for structured data)
    waste_type  TEXT,                             -- pipi, caca, les_deux (diaper events only)
    color       TEXT,                             -- couleur de la selle ou pipi (see tracking_enums.dart)
    texture     TEXT,                             -- stool texture: aqueuse|grumeleuse|pateuse|moulee|dure (see tracking_enums.dart)
    baby_id     TEXT,                             -- nullable FK to baby_profiles(id), backward compatible
    quantity    REAL                              -- volume in ml (feeding) or minutes (sleep)
);

CREATE INDEX idx_tracking_events_type ON tracking_events(type);

CREATE INDEX idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type);

-- ── Reminder Dismissals ──────────────────────────────────────────

CREATE TABLE reminder_dismissals (
    item_id     TEXT PRIMARY KEY NOT NULL,         -- matches ReminderItem.id
    dismissed_at TIMESTAMP            NOT NULL     -- when the user last dismissed this reminder
);

-- ── Reminder Settings ──────────────────────────────────────────

CREATE TABLE reminder_settings (
    item_id     TEXT PRIMARY KEY NOT NULL,         -- matches ReminderItem.id — a custom reminder uses 'custom_<id>'
    enabled     BOOLEAN            NOT NULL        -- whether this reminder is enabled
);

-- ── Custom Reminders ───────────────────────────────────────────

CREATE TABLE custom_reminders (
    id            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    label         TEXT                              NOT NULL,  -- parent's own wording, 1..60 chars
    subtype_value TEXT                              NOT NULL,  -- HealthSubtype value: the care whose absence makes the reminder due
    frequency     TEXT                              NOT NULL,  -- daily | weekly | monthly | every_n_days
    interval_days INTEGER                            -- only for every_n_days: rolling length in days
);
