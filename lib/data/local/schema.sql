-- Mamadera Database Schema
-- Version: 1
-- Source : lib/data/local/app_db.dart (TrackingEvents)

CREATE TABLE tracking_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    type        TEXT                              NOT NULL,
    timestamp   TIMESTAMP                         NOT NULL,
    duration    REAL,                             -- en minutes (pour dodo et sein)
    notes       TEXT                               -- notes libres optionnelles
);

-- Index : filtrage par type → accélère getEventsByType(), getFeedingEvents()
CREATE INDEX idx_tracking_events_type ON tracking_events(type);

-- Index composite : tri chronologique + type → accélère getAllEventsOrdered() et requêtes combinées
CREATE INDEX idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type);

