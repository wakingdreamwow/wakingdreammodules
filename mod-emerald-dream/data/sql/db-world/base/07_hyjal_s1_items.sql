-- =============================================================================
-- Hyjal Zone S1: Quest reward items + quest objective items
--
-- Vigil-of-Nordrassil v1: 5 quest-reward items (ilvl 245-251, blue, universal
-- slot types — Ring/Neck/Trinket/Back — to sidestep armor-type restrictions for
-- the first cut) + 2 quest objective items (Faded Page, Hyjal Wildflower).
--
-- All items BoP, quest reward type. Idempotent.
-- =============================================================================

DELETE FROM `item_template` WHERE `entry` BETWEEN 990060 AND 990069;

-- -----------------------------------------------------------------------------
-- 990060 — Watcher's Signet (Ring, ilvl 245, melee-leaning)
-- Reward for Q990050 "The Watch of the Worldtree"
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stat_type1`,`stat_value1`,`stat_type2`,`stat_value2`,`stat_type3`,`stat_value3`,
  `bonding`,`description`,`Material`,`sheath`)
VALUES
 (990060,4,0,'Watcher''s Signet',38486,3,0,1,18000,4500,
  11,-1,-1,245,80,
  7,28,4,20,32,18,
  1,'A simple silver band etched with Nordrassil leaves.',0,0);

-- -----------------------------------------------------------------------------
-- 990061 — Wisp Reliquary (Neck, ilvl 245, caster-leaning)
-- Reward for Q990051 "First Signs"
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stat_type1`,`stat_value1`,`stat_type2`,`stat_value2`,`stat_type3`,`stat_value3`,
  `bonding`,`description`,`Material`,`sheath`)
VALUES
 (990061,4,0,'Wisp Reliquary',39492,3,0,1,20000,5000,
  2,-1,-1,245,80,
  7,34,5,24,45,18,
  1,'A glass vial sealed with druidic runes. A faint blue light still drifts within.',0,0);

-- -----------------------------------------------------------------------------
-- 990062 — Embrace of Nordrassil (Trinket, ilvl 251, universal Use-effect)
-- Reward for Q990052 "The Dream Calls" — the chain climax piece
-- Use: Heroism-style stat buff for 20 sec, 3 min cooldown
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stat_type1`,`stat_value1`,
  `spellid_1`,`spelltrigger_1`,`spellcharges_1`,`spellcooldown_1`,`spellcategory_1`,`spellcategorycooldown_1`,
  `bonding`,`description`,`Material`,`sheath`)
VALUES
 (990062,4,0,'Embrace of Nordrassil',40674,3,0,1,30000,7500,
  12,-1,-1,251,80,
  7,60,
  53908,0,-1,180000,0,0,
  1,'Wrapped in living bark warmed by the Worldtree itself.',0,0);
 -- spellid 53908 = "Speed" trinket effect (Lightweave Embroidery-style temp +AP/SP)
 -- spelltrigger 0 = ON USE
 -- spellcharges -1 = unlimited
 -- spellcooldown 180000 = 3 minutes

-- -----------------------------------------------------------------------------
-- 990063 — Faded Cenarion Page (Quest Item, no stats)
-- Objective for Q990053 "Wisdom of the Grove"
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stackable`,`maxcount`,`bonding`,`description`,`Material`,`sheath`)
VALUES
 (990063,12,0,'Faded Cenarion Page',5564,1,64,1,0,0,
  0,-1,-1,1,1,
  10,10,1,'A weathered fragment of druidic lore.',0,0);
 -- class 12 = Quest item
 -- Flag 64 = NoDestroy
 -- displayid 5564 = generic parchment

-- -----------------------------------------------------------------------------
-- 990064 — Antler-Wrought Cloak (Back, ilvl 245, physical-leaning)
-- Reward for Q990053 "Wisdom of the Grove"
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stat_type1`,`stat_value1`,`stat_type2`,`stat_value2`,`stat_type3`,`stat_value3`,
  `armor`,`bonding`,`description`,`Material`,`sheath`)
VALUES
 (990064,4,1,'Antler-Wrought Cloak',43935,3,0,1,22000,5500,
  16,-1,-1,245,80,
  7,36,3,22,31,18,
  247,1,'A heavy cloak fastened with twin antler clasps. It smells of moss and old smoke.',7,0);
 -- subclass 1 = Cloth (cloaks are all cloth subclass)
 -- InventoryType 16 = Back
 -- material 7 = Cloth

-- -----------------------------------------------------------------------------
-- 990065 — Hyjal Wildflower (Quest Item, no stats, stackable)
-- Objective for Q990054 "Restock the Watch"
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stackable`,`maxcount`,`bonding`,`description`,`Material`,`sheath`)
VALUES
 (990065,12,0,'Hyjal Wildflower',7027,1,64,1,0,0,
  0,-1,-1,1,1,
  20,20,1,'A pale blue bloom dusted with starlight pollen. Treasured by Cenarion healers.',0,0);
 -- displayid 7027 = generic blue flower icon

-- -----------------------------------------------------------------------------
-- 990066 — Hyjal Sentinel's Band (Ring 2, ilvl 245, healer-leaning)
-- Reward for Q990054 "Restock the Watch"
-- -----------------------------------------------------------------------------
INSERT INTO `item_template`
 (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`BuyPrice`,`SellPrice`,
  `InventoryType`,`AllowableClass`,`AllowableRace`,`ItemLevel`,`RequiredLevel`,
  `stat_type1`,`stat_value1`,`stat_type2`,`stat_value2`,`stat_type3`,`stat_value3`,
  `bonding`,`description`,`Material`,`sheath`)
VALUES
 (990066,4,0,'Hyjal Sentinel''s Band',38486,3,0,1,18000,4500,
  11,-1,-1,245,80,
  7,28,6,20,45,18,
  1,'A silver band engraved with the crescent of Elune.',0,0);
 -- Stats: Stamina, Spirit, Spell Power (3-stat healer flex)

-- =============================================================================
-- DONE. Reload via `.reload item_template` or `.server restart`.
-- =============================================================================
