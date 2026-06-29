-- =============================================================================
-- Hyjal Zone S1: Nordrassil Summit Hub (Cenarion Circle staging ground)
--
-- Player journey: Duskwood portal -> Nordrassil summit -> Tyrande Whisperwind
-- -> talk to Cenarion ensemble (Remulos / Quartermaster / Druid Aerin / 3 scouts)
-- -> meet Ysera -> existing Albtraum arc (990020 / 990021).
--
-- Soft-gates the future S3/S4/S5 arcs via three scout NPCs (990045/46/47) who
-- speak placeholder gossip until the Nightmare Lord (Q990021) is defeated.
--
-- Idempotent. Re-runnable. enUS only per project loc rule.
-- =============================================================================

-- ---- ID anchors --------------------------------------------------------------
SET @TYRANDE          := 990040; -- repurposed from former Archdruide Maldoran
SET @REMULOS          := 990041;
SET @WISP_CORRUPT     := 990042; -- mob (kept from prior build)
SET @QUARTERMASTER    := 990043;
SET @AERIN            := 990044;
SET @SCOUT_CRATER     := 990045; -- S4 hook, soft-gated
SET @SCOUT_GLADE      := 990046; -- S5 hook, soft-gated
SET @WATCHER_WELL     := 990047; -- S3 hook, soft-gated

SET @INIT_M           := 990030; -- ambient initiates
SET @INIT_F           := 990031;
SET @TREANT_SAPLING   := 990032;
SET @DRUID_WILD       := 990033;
SET @MOONGLADE_STAG   := 990034;
SET @NORDRASSIL_OWL   := 990035;
SET @WISP_NORDRASSIL  := 990036; -- ambient (vs corrupted wisp mob 990042)

SET @YSERA            := 990011; -- existing
SET @ALBTRAUM1        := 990020; -- existing (Schemen quest)
SET @ALBTRAUM2        := 990021; -- existing (Lord quest)

-- Quest IDs
SET @QA1              := 990050; -- The Watch of the Worldtree (Tyrande intro)
SET @QA2              := 990051; -- First Signs (kill 5 Corrupted Wisps)
SET @QA3              := 990052; -- The Dream Calls (go to Ysera)
SET @QA4              := 990053; -- Wisdom of the Grove (Remulos side quest)
SET @QA5              := 990054; -- Restock the Watch (Quartermaster side quest)

-- GameObject IDs
SET @GO_BRAZIER       := 990100;
SET @GO_BANNER        := 990101;
SET @GO_STANDARD      := 990102;
SET @GO_CAMPFIRE      := 990103;
SET @GO_MOSSY_STONE   := 990104;
SET @GO_SUPPLY_CRATE  := 990105;
SET @GO_HERB_PATCH    := 990106;

-- ---- CLEAN -------------------------------------------------------------------
DELETE FROM `creature` WHERE `id1` IN (
  @TYRANDE,@REMULOS,@WISP_CORRUPT,@QUARTERMASTER,@AERIN,
  @SCOUT_CRATER,@SCOUT_GLADE,@WATCHER_WELL,
  @INIT_M,@INIT_F,@TREANT_SAPLING,@DRUID_WILD,
  @MOONGLADE_STAG,@NORDRASSIL_OWL,@WISP_NORDRASSIL
);

DELETE FROM `creature_queststarter` WHERE `quest` IN (@QA1,@QA2,@QA3,@QA4,@QA5);
DELETE FROM `creature_questender`   WHERE `quest` IN (@QA1,@QA2,@QA3,@QA4,@QA5);
DELETE FROM `quest_template_addon`  WHERE `ID`    IN (@QA1,@QA2,@QA3,@QA4,@QA5,@ALBTRAUM1);
DELETE FROM `quest_template`        WHERE `ID`    IN (@QA1,@QA2,@QA3,@QA4,@QA5);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (
  @TYRANDE,@REMULOS,@WISP_CORRUPT,@QUARTERMASTER,@AERIN,
  @SCOUT_CRATER,@SCOUT_GLADE,@WATCHER_WELL,
  @INIT_M,@INIT_F,@TREANT_SAPLING,@DRUID_WILD,
  @MOONGLADE_STAG,@NORDRASSIL_OWL,@WISP_NORDRASSIL
);
DELETE FROM `creature_template` WHERE `entry` IN (
  @TYRANDE,@REMULOS,@WISP_CORRUPT,@QUARTERMASTER,@AERIN,
  @SCOUT_CRATER,@SCOUT_GLADE,@WATCHER_WELL,
  @INIT_M,@INIT_F,@TREANT_SAPLING,@DRUID_WILD,
  @MOONGLADE_STAG,@NORDRASSIL_OWL,@WISP_NORDRASSIL
);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 5400200 AND 5400239;

DELETE FROM `creature_text` WHERE `CreatureID` IN (@TYRANDE,@REMULOS,@WATCHER_WELL);

-- =============================================================================
-- CREATURE TEMPLATES — hub ensemble
-- =============================================================================

-- Tyrande Whisperwind (Hub Lead, intro questgiver + ender, immune)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@TYRANDE,'Tyrande Whisperwind','High Priestess of Elune',80,80,35,3,1,768,7,'',0,200,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@TYRANDE,0,27950,1.0,1,0);

-- Keeper Remulos (Lore-flavor questgiver — side quest QA4)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@REMULOS,'Keeper Remulos','Son of Cenarius',80,80,35,3,1,768,7,'',0,200,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@REMULOS,0,15276,1.0,1,0);

-- Corrupted Wisp (mob for QA2 "First Signs", lvl80 trash)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@WISP_CORRUPT,'Corrupted Wisp','',80,80,14,0,1,0,1,'',0,2,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@WISP_CORRUPT,0,10045,1.0,1,0);

-- Cenarion Quartermaster Thalanaar (vendor + side questgiver QA5)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@QUARTERMASTER,'Cenarion Quartermaster Thalanaar','Vendor',80,80,35,131,1,768,7,'',0,150,1,1,1); -- npcflag 131 = gossip+quest+vendor
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@QUARTERMASTER,0,17040,1.0,1,0);

-- Druid of the Talon Aerin (repair NPC)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@AERIN,'Druid Aerin','Innkeeper',80,80,35,4225,1,768,7,'',0,150,1,1,1); -- npcflag 4225 = gossip+vendor+repairer+innkeeper
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@AERIN,0,16863,1.0,1,0);

-- Ranger-Captain Faedris (S4 Crater hook, soft-gated for now)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@SCOUT_CRATER,'Ranger-Captain Faedris','Watcher of the Scar',80,80,35,1,1,768,7,'',0,150,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@SCOUT_CRATER,0,22815,1.0,1,0);

-- Scout Mira'lia (S5 Glade hook, soft-gated)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@SCOUT_GLADE,'Scout Mira''lia','Watcher of the Embers',80,80,35,1,1,768,7,'',0,150,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@SCOUT_GLADE,0,22815,1.0,1,0);

-- Watcher of the Well (S3 Well hook, soft-gated)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@WATCHER_WELL,'Watcher Elidran','Keeper of the Well',80,80,35,1,1,768,7,'',0,150,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@WATCHER_WELL,0,17040,1.0,1,0);

-- Ambient: Cenarion Initiate (male) — atmosphere, idle SmartAI
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@INIT_M,'Cenarion Initiate','',78,80,35,0,1,768,7,'',0,30,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@INIT_M,0,17040,1.0,1,0);

-- Ambient: Cenarion Initiate (female)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@INIT_F,'Cenarion Initiate','',78,80,35,0,1,768,7,'',0,30,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@INIT_F,0,16863,1.0,1,0);

-- Ambient: Treant Sapling
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@TREANT_SAPLING,'Treant Sapling','',78,80,35,0,1,768,1,'',0,15,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@TREANT_SAPLING,0,11104,0.7,1,0);

-- Ambient: Druid of the Wild (bear form, patrols)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@DRUID_WILD,'Druid of the Wild','',78,80,35,0,1,768,1,'',1,30,1,1,1); -- MovementType 1 = wander
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@DRUID_WILD,0,4087,1.0,1,0);

-- Ambient: Moonglade Stag
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@MOONGLADE_STAG,'Moonglade Stag','',76,80,35,0,1,768,1,'',1,12,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@MOONGLADE_STAG,0,477,1.0,1,0);

-- Ambient: Nordrassil Owl (perched / flying)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@NORDRASSIL_OWL,'Nordrassil Owl','',76,80,35,0,1,768,1,'',1,8,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@NORDRASSIL_OWL,0,6147,1.0,1,0);

-- Ambient: Wisp of Nordrassil (friendly, vs corrupted wisp 990042)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@WISP_NORDRASSIL,'Wisp of Nordrassil','',76,80,35,0,1,768,1,'',1,4,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@WISP_NORDRASSIL,0,4636,1.0,1,0);

-- =============================================================================
-- CREATURE TEXT — flavor lines
-- =============================================================================

-- Tyrande: hub welcome text (announced via SmartAI on_los, set up at spawn time)
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@TYRANDE,0,0,'Welcome to Nordrassil, traveler. Even in this hour of shadow, the Worldtree still stands.',12,7,100,0,0,0,0,0,'Tyrande greeting'),
 (@TYRANDE,1,0,'May Elune guide your hand.',12,7,100,0,0,0,0,0,'Tyrande farewell');

-- Remulos: quiet wisdom flavor
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@REMULOS,0,0,'The roots remember. The leaves whisper. The Dream waits.',12,7,100,0,0,0,0,0,'Remulos ambient');

-- Watcher of the Well: gating hint text
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@WATCHER_WELL,0,0,'The Well still calls... but I cannot guide you there yet. First, the Dream must be cleansed.',12,7,100,0,0,0,0,0,'Watcher gate hint');

-- =============================================================================
-- QUEST TEMPLATES — Hub chain + 2 side quests
-- =============================================================================

-- QA1: "The Watch of the Worldtree" — intro, talk to Tyrande
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`QuestCompletionLog`,`RewardItem1`,`RewardAmount1`)
VALUES (@QA1,2,80,80,0,50000,0,'The Watch of the Worldtree',
 'Welcome to Nordrassil, $N. I am Tyrande Whisperwind. The Worldtree has stood since the fall of the Burning Legion, yet new shadows stir at its roots. The Emerald Dream rots, fire churns deep below, and the scars of the Legion smolder still in the crater above. We need every hand we can find. Speak with my watchers across this hold — learn their burdens. Return to me when you have walked among them.',
 'Speak with the Cenarion watch around Nordrassil, then return to Tyrande.',
 990060,1); -- starter quest reward: a Cenarion Wristguard (ilvl 245, defined in 07_items.sql)
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@TYRANDE,@QA1);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@TYRANDE,@QA1);

-- QA2: "First Signs" — kill 5 Corrupted Wisps
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`RewardItem1`,`RewardAmount1`)
VALUES (@QA2,2,80,80,0,100000,0,'First Signs',
 'Even here, on hallowed ground, the rot reaches us — corrupted wisps drift among the roots, their light turned sickly. Release five of them, $N, so we may know how deep the Nightmare has bled.',
 'Corrupted Wisps released',@WISP_CORRUPT,5,
 990061,1); -- reward: Vigil Sash (ilvl 245, defined in 07_items.sql)
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@QA2,@QA1);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@TYRANDE,@QA2);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@TYRANDE,@QA2);

-- QA3: "The Dream Calls" — travel Tyrande -> Ysera; opens Albtraum arc
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`QuestCompletionLog`,`RewardItem1`,`RewardAmount1`)
VALUES (@QA3,2,80,80,0,100000,0,'The Dream Calls',
 'The source of the corruption lies within the Emerald Dream itself. Only one can guide you there: Ysera, the Dreamer. She keeps watch at our summit — kneel before her, $N, and follow her call into the Dream below.',
 'Speak with Ysera at the summit.',
 990062,1); -- reward: Vigil Hood (ilvl 251, defined in 07_items.sql)
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@QA3,@QA2);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@TYRANDE,@QA3);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@YSERA,@QA3);

-- QA4: "Wisdom of the Grove" — side quest, Remulos. Gather 4 Faded Cenarion Pages.
-- Pages spawn as quest objects (handle via gameobject + areatrigger or simple gather count — using gameobject for now)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredItemId1`,`RequiredItemCount1`,`RewardItem1`,`RewardAmount1`)
VALUES (@QA4,2,80,80,0,100000,0,'Wisdom of the Grove',
 'Before the Legion fell here, the druids of Hyjal kept their lore on parchment and bark. Many of those pages were scattered in the battle. Find four faded pages, $N — they are still here, drifting beneath the roots — and bring them to me. Through them we remember.',
 'Faded Cenarion Pages collected',990063,4, -- item 990063 = Faded Cenarion Page (quest item)
 990064,1); -- reward: Antler-Wrought Cloak (ilvl 245)
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@REMULOS,@QA4);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@REMULOS,@QA4);

-- QA5: "Restock the Watch" — side quest, Quartermaster. Gather 8 Hyjal Wildflowers.
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredItemId1`,`RequiredItemCount1`,`RewardItem1`,`RewardAmount1`)
VALUES (@QA5,2,80,80,0,80000,0,'Restock the Watch',
 'Our healers run dry, $N. The wildflowers of Hyjal still bloom along the roots — gentle blue, dusted with starlight. Gather eight blooms for me, and the Watch will mend a little faster.',
 'Hyjal Wildflowers gathered',990065,8, -- item 990065 = Hyjal Wildflower (quest item)
 990066,1); -- reward: Hyjal Sentinel''s Belt (ilvl 245)
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@QUARTERMASTER,@QA5);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@QUARTERMASTER,@QA5);

-- ---- GATE: existing Albtraum arc requires QA3 done ---------------------------
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@ALBTRAUM1,@QA3);

-- =============================================================================
-- SPAWNS — NPCs at Nordrassil summit
-- =============================================================================
-- NOTE: These are PLACEHOLDER coordinates near the hub anchor (5373, -3379, 1655.5).
-- Daniel will refine ingame via .npc add per the spec checklist. The DELETEs above
-- handle re-runs, and Daniel's positions will be auto-saved to creature table.
-- The seeds below give a starting tableau if no .npc add is done yet.

INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301200,@TYRANDE,0,0,1,0,0,1,1,0,5373,-3379,1655.5,3.9,300,0,0,1,0,0,0,0,0,'',0,0,'Tyrande Whisperwind (hub lead, replaces former Maldoran)'),
 -- Corrupted Wisps (QA2 mobs, ground around plateau)
 (5301201,@WISP_CORRUPT,0,0,1,0,0,1,1,0,5360,-3400,1655.5,1.0,300,4,0,1,0,0,0,0,0,'',0,0,'Corrupted Wisp'),
 (5301202,@WISP_CORRUPT,0,0,1,0,0,1,1,0,5350,-3395,1655.5,1.5,300,4,0,1,0,0,0,0,0,'',0,0,'Corrupted Wisp'),
 (5301203,@WISP_CORRUPT,0,0,1,0,0,1,1,0,5368,-3408,1655.5,2.0,300,4,0,1,0,0,0,0,0,'',0,0,'Corrupted Wisp'),
 (5301204,@WISP_CORRUPT,0,0,1,0,0,1,1,0,5345,-3405,1655.5,2.5,300,4,0,1,0,0,0,0,0,'',0,0,'Corrupted Wisp'),
 (5301205,@WISP_CORRUPT,0,0,1,0,0,1,1,0,5358,-3413,1655.5,3.0,300,4,0,1,0,0,0,0,0,'',0,0,'Corrupted Wisp'),
 (5301206,@WISP_CORRUPT,0,0,1,0,0,1,1,0,5372,-3400,1655.5,0.5,300,4,0,1,0,0,0,0,0,'',0,0,'Corrupted Wisp'),
 -- Seed ensemble (Daniel to refine via .npc add)
 (5301210,@REMULOS,0,0,1,0,0,1,1,0,5385,-3372,1655.5,3.5,300,0,0,1,0,0,0,0,0,'',0,0,'Keeper Remulos (refine spot)'),
 (5301211,@QUARTERMASTER,0,0,1,0,0,1,1,0,5388,-3389,1655.5,3.2,300,0,0,1,0,0,0,0,0,'',0,0,'Quartermaster (refine spot)'),
 (5301212,@AERIN,0,0,1,0,0,1,1,0,5365,-3370,1655.5,2.0,300,0,0,1,0,0,0,0,0,'',0,0,'Aerin (refine spot)'),
 (5301213,@SCOUT_CRATER,0,0,1,0,0,1,1,0,5380,-3360,1655.5,0.8,300,0,0,1,0,0,0,0,0,'',0,0,'Ranger-Captain Faedris (refine spot)'),
 (5301214,@SCOUT_GLADE,0,0,1,0,0,1,1,0,5358,-3390,1655.5,4.5,300,0,0,1,0,0,0,0,0,'',0,0,'Scout Mira''lia (refine spot)'),
 (5301215,@WATCHER_WELL,0,0,1,0,0,1,1,0,5377,-3395,1655.5,2.5,300,0,0,1,0,0,0,0,0,'',0,0,'Watcher Elidran (refine spot)'),
 -- Ambient seeds (Daniel to multiply / refine)
 (5301220,@INIT_M,0,0,1,0,0,1,1,0,5370,-3375,1655.5,1.0,300,3,0,1,0,0,0,0,0,'',0,0,'Initiate seed'),
 (5301221,@INIT_F,0,0,1,0,0,1,1,0,5379,-3380,1655.5,5.5,300,3,0,1,0,0,0,0,0,'',0,0,'Initiate seed'),
 (5301222,@TREANT_SAPLING,0,0,1,0,0,1,1,0,5380,-3395,1655.5,2.0,300,3,0,1,0,0,0,0,0,'',0,0,'Treant seed'),
 (5301223,@MOONGLADE_STAG,0,0,1,0,0,1,1,0,5370,-3411,1655.5,4.5,300,5,0,1,0,0,0,0,0,'',0,0,'Stag seed (wanders)'),
 (5301224,@NORDRASSIL_OWL,0,0,1,0,0,1,1,0,5388,-3382,1657,0.5,300,5,0,1,0,0,0,0,0,'',0,0,'Owl seed (wanders)'),
 (5301225,@WISP_NORDRASSIL,0,0,1,0,0,1,1,0,5371,-3385,1656,1.0,300,3,0,1,0,0,0,0,0,'',0,0,'Wisp seed');

-- =============================================================================
-- GAMEOBJECT SEEDS — hub deco
-- =============================================================================
-- Seed two braziers as before (kept from prior build). Daniel adds more
-- via .gobject add. The 5400200-5400239 range cleanup above handles re-runs.

INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES
 (5400200,20975,1,0,0,1,1,5377,-3375,1655.5,0,0,0,0,1,300,255,1,'',0,'Hub Brazier (seed)'),
 (5400201,20975,1,0,0,1,1,5369,-3383,1655.5,0,0,0,0,1,300,255,1,'',0,'Hub Brazier (seed)');

-- =============================================================================
-- VENDOR INVENTORY — Cenarion Quartermaster sells basic consumables
-- =============================================================================
DELETE FROM `npc_vendor` WHERE `entry`=@QUARTERMASTER;
INSERT INTO `npc_vendor` (`entry`,`slot`,`item`,`maxcount`,`incrtime`,`ExtendedCost`,`VerifiedBuild`) VALUES
 (@QUARTERMASTER,0,33444,0,0,0,0),    -- Honeymint Tea (drink)
 (@QUARTERMASTER,1,33445,0,0,0,0),    -- Honey Bread
 (@QUARTERMASTER,2,33447,0,0,0,0),    -- Pungent Seal Whey
 (@QUARTERMASTER,3,43086,0,0,0,0),    -- Tundra Spring Water
 (@QUARTERMASTER,4,33092,0,0,0,0),    -- Frostweave Bandage
 (@QUARTERMASTER,5,33208,0,0,0,0),    -- Heavy Frostweave Bandage
 (@QUARTERMASTER,6,33934,0,0,0,0),    -- Endless Mana Potion (rune)
 (@QUARTERMASTER,7,33933,0,0,0,0);    -- Endless Healing Potion (rune)

-- =============================================================================
-- DONE. Apply via worldserver-reload or restart.
-- =============================================================================
