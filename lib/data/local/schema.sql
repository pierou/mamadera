-- Mamadera Database Schema
-- Version: 11
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
--   v11: Re-keyed `reminder_settings` and `reminder_dismissals` per baby
--        (composite PK (baby_id, item_id); '' = shared by all babies, never
--        NULL); rebuilt `custom_reminders` (baby_id, nullable subtype_value,
--        completion_source); created `measurements` and `reminder_completions`
--        with two indexes

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
    baby_id      TEXT    NOT NULL DEFAULT '',      -- '' = shared by all babies (sentinel), never NULL
    item_id      TEXT    NOT NULL,                -- matches ReminderItem.id
    dismissed_at TIMESTAMP NOT NULL,              -- when the user last dismissed this reminder for this baby
    PRIMARY KEY (baby_id, item_id)
);

-- ── Reminder Settings ──────────────────────────────────────────

CREATE TABLE reminder_settings (
    baby_id      TEXT    NOT NULL DEFAULT '',      -- '' = shared by all babies (sentinel), never NULL
    item_id      TEXT    NOT NULL,                -- matches ReminderItem.id — a custom reminder uses 'custom_<id>'
    enabled      BOOLEAN NOT NULL,                -- whether this reminder is enabled for this baby
    PRIMARY KEY (baby_id, item_id)
);

-- ── Custom Reminders ───────────────────────────────────────────

CREATE TABLE custom_reminders (
    id               INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    baby_id          TEXT    NOT NULL DEFAULT '',          -- '' = shared by all babies (sentinel)
    label            TEXT                              NOT NULL,  -- parent's own wording, 1..60 chars
    subtype_value    TEXT,                                 -- HealthSubtype value: the care whose absence makes the reminder due — NULL = detached reminder (manual completion only)
    frequency        TEXT    NOT NULL,                     -- daily | weekly | monthly | every_n_days
    interval_days    INTEGER,                              -- only for every_n_days: rolling length in days
    completion_source TEXT    NOT NULL DEFAULT 'from_events'  -- from_events | manual: what settles the reminder (migrated rows default to 'from_events', fresh installs to '')
);

-- ── Measurements ───────────────────────────────────────────────

CREATE TABLE measurements (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    baby_id     TEXT,                               -- nullable, like tracking_events.baby_id
    kind        TEXT                              NOT NULL,  -- poids | taille | temperature
    value       TEXT                              NOT NULL,  -- AES-GCM ciphertext (iv:ciphertext base64), not a number
    unit        TEXT                              NOT NULL,  -- g | cm | degC
    recorded_at TIMESTAMP                         NOT NULL,
    notes       TEXT,                               -- encrypted, same pipeline as tracking events
);

CREATE INDEX idx_measurements_baby_kind_recorded ON measurements(baby_id, kind, recorded_at DESC);

-- ── Reminder Completions ───────────────────────────────────────

CREATE TABLE reminder_completions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    baby_id     TEXT                              NOT NULL,  -- '' = shared by all babies (sentinel), never NULL
    item_id     TEXT                              NOT NULL,  -- matches ReminderItem.id
    completed_at TIMESTAMP                        NOT NULL   -- append-only log: one row per "done" tap
);

CREATE INDEX idx_reminder_completions_baby_item ON reminder_completions(baby_id, item_id, completed_at DESC);
