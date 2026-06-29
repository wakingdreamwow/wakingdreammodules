-- World boss roster (which creatures are event bosses + type). Idempotent.
CREATE TABLE IF NOT EXISTS `event_worldbosses` (
  `entry` INT UNSIGNED NOT NULL PRIMARY KEY,
  `is_elite` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `loot_quality` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `comment` VARCHAR(120) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `event_worldbosses` WHERE `entry`=990001;
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`,`comment`) VALUES (990001,1,3,'Glutwyrm test - elite, blue loot');
