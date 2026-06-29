-- Tracks which characters already received the starter kit (one-time guard). Characters DB.
CREATE TABLE IF NOT EXISTS `character_starterkit` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `given_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
