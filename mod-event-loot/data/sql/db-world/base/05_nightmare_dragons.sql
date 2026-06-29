-- Dragons of Nightmare integrated into the world-boss system (Nightmare tier).
-- They already have canonical spawns guarding the four Emerald Dream groves; this just
-- adds them to our roster so they grant personal loot + immersive helper-bot assist.
-- Taerar = Twilight Grove (Duskwood). All lvl63 raid dragons. Idempotent.
DELETE FROM `event_worldbosses` WHERE `entry` IN (14887,14888,14889,14890);
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`,`comment`) VALUES
 (14890,1,4,'Taerar - Twilight Grove (Duskwood) nightmare dragon'),
 (14887,1,4,'Ysondre - nightmare dragon (grove guardian)'),
 (14889,1,4,'Emeriss - nightmare dragon (grove guardian)'),
 (14888,1,4,'Lethon - nightmare dragon (grove guardian)');
