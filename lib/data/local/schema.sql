-- Mamadera Database Schema
-- Version: 3
-- Source : lib/data/local/app_db.dart (TrackingEvents + ReminderDismissals)

CREATE TABLE tracking_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    type        TEXT                              NOT NULL,
    timestamp   TIMESTAMP                         NOT NULL,
    duration    REAL,                             -- en minutes (pour dodo et sein)
    notes       TEXT,                             -- subtype string OR encrypted user text
    waste_type  TEXT,                             -- pipi, caca, les_deux
    color       TEXT                              -- couleur de la selle ou pipe-délimitée (pipi|caca)
);

-- Index : filtrage par type → accélère getEventsByType(), getFeedingEvents()
CREATE INDEX idx_tracking_events_type ON tracking_events(type);

-- Index composite : tri chronologique + type → accélère getAllEventsOrdered() et requêtes combinées
CREATE INDEX idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type);

-- ── Reminder Dismissals ────────────────────────────────────────────────

CREATE TABLE reminder_dismissals (
    item_id     TEXT PRIMARY KEY NOT NULL,         -- matches ReminderItem.id
    dismissed_at TIMESTAMP            NOT NULL     -- when the user last dismissed this reminder
);

