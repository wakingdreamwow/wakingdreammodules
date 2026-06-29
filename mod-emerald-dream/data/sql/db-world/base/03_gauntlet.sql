-- Emerald Dream Stage 4: "Der Abstieg in den Albtraum" — timed-gauntlet descent (Hyjal, map 1).
-- Akt 1 (Q2 travel) + Akt 2 (Q3 hordes, Q4 mini-bosses). Re-links Lord quest 990021 to end of gauntlet.
-- Idempotent. Geometry from Daniel .gps waypoints (verified ground).
SET @HUETER:=990015; SET @BEAST:=990016; SET @HIPPO:=990017; SET @MB1:=990018; SET @MB2:=990019;
SET @YSERA:=990011; SET @LORD:=990014;
SET @Q1:=990020; SET @Q2:=990022; SET @Q3:=990023; SET @Q4:=990024; SET @Q5:=990021;

-- ---- cleanup (idempotent) ----
DELETE FROM `creature` WHERE `id1` IN (@HUETER,@BEAST,@HIPPO,@MB1,@MB2);
DELETE FROM `creature_queststarter` WHERE `quest` IN (@Q2,@Q3,@Q4,@Q5);
DELETE FROM `creature_questender`   WHERE `quest` IN (@Q2,@Q3,@Q4,@Q5);
DELETE FROM `quest_template_addon`  WHERE `ID` IN (@Q2,@Q3,@Q4,@Q5);
DELETE FROM `quest_template`        WHERE `ID` IN (@Q2,@Q3,@Q4);
DELETE FROM `event_worldbosses`     WHERE `entry` IN (@MB1,@MB2);
DELETE FROM `creature_text`         WHERE `CreatureID` IN (@HUETER,@MB1,@MB2);
DELETE FROM `smart_scripts`         WHERE `entryorguid` IN (@HUETER,@MB1,@MB2) AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@HUETER,@BEAST,@HIPPO,@MB1,@MB2);
DELETE FROM `creature_template`     WHERE `entry` IN (@HUETER,@BEAST,@HIPPO,@MB1,@MB2);

-- ===================== CREATURE TEMPLATES =====================
-- Hueter des Pfades (gauntlet questgiver, immune, Keeper-of-the-Grove look)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@HUETER,'Hueter des Pfades','Waechter des Abstiegs',80,80,35,3,1,768,7,'SmartAI',0,50,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@HUETER,0,11906,1.0,1,0);

-- Albtraum-Bestie (horde trash, corrupted bear)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@BEAST,'Albtraum-Bestie','',80,80,14,0,1,0,1,'',0,5,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@BEAST,0,17342,1.1,1,0);

-- Verdorbener Hippogryph (horde trash, flier)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@HIPPO,'Verdorbener Hippogryph','',80,80,14,0,1,0,1,'',0,4,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@HIPPO,0,22471,1.0,1,0);

-- Mini-Boss 1: Naralassa, die Traumweberin (corrupted green dragon, elite)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`)
VALUES (@MB1,'Naralassa','die Traumweberin',80,80,14,0,1,0,2,'SmartAI',0,50,1,1,1,2);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@MB1,0,14888,1.15,1,0);

-- Mini-Boss 2: Gnarl, der Albtraum-Waechter (giant nightmare shade, elite)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`)
VALUES (@MB2,'Gnarl','der Albtraum-Waechter',80,80,14,0,1,0,6,'SmartAI',0,55,1,1,1,2);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@MB2,0,10553,2.2,1,0);

-- ===================== TEXTS =====================
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@HUETER,0,0,'Halt, Sterblicher. Jenseits dieses Pfades wartet nur der Albtraum.',1,0,100,0,0,0,0,0,'Hueter greet'),
 (@MB1,0,0,'Der Traum wird dich verschlingen!',14,0,100,0,0,0,0,0,'Naralassa aggro'),
 (@MB1,1,0,'Ysera... vergib mir...',14,0,100,0,0,0,0,0,'Naralassa death'),
 (@MB2,0,0,'Kein Erwachen fuer dich!',14,0,100,0,0,0,0,0,'Gnarl aggro'),
 (@MB2,1,0,'Der Albtraum... bleibt...',14,0,100,0,0,0,0,0,'Gnarl death');

-- ===================== SMART SCRIPTS =====================
-- Hueter: greet on LOS (long cooldown)
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
 (@HUETER,0,0,0,10,0,100,0,1,25,300000,300000,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hueter greets on LOS');

-- Naralassa: aggro yell, Noxious Breath, Enrage<25%, death yell
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
 (@MB1,0,0,1,4,0,100,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Naralassa aggro yell'),
 (@MB1,0,1,0,0,0,100,0,7000,12000,10000,15000,0,0,11,24818,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Naralassa Noxious Breath'),
 (@MB1,0,2,0,2,0,100,0,0,25,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Naralassa Enrage <25%'),
 (@MB1,0,3,0,6,0,100,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Naralassa death yell');

-- Gnarl: aggro yell, shadow AoE, Enrage<25%, death yell
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
 (@MB2,0,0,1,4,0,100,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Gnarl aggro yell'),
 (@MB2,0,1,0,0,0,100,0,9000,14000,12000,18000,0,0,11,66813,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Gnarl shadow AoE'),
 (@MB2,0,2,0,2,0,100,0,0,25,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Gnarl Enrage <25%'),
 (@MB2,0,3,0,6,0,100,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Gnarl death yell');

-- ===================== WORLDBOSS LOOT (mini-bosses, rare) =====================
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`) VALUES (@MB1,0,3),(@MB2,0,3);

-- ===================== SPAWNS =====================
-- Hueter at WP1 (top of descent), facing valley
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300760,@HUETER,0,0,1,0,0,1,1,0,5202.42,-3327.06,1643.66,4.6,300,0,0,1,0,0,0,0,0,'',0,0,'Hueter des Pfades (WP1)');

-- Horde wave 1 @ WP1 (offset toward valley)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300770,@BEAST,0,0,1,0,0,1,1,0,5208,-3334,1643.66,4.6,300,0,0,1,0,0,0,0,0,'',0,0,'Horde1 Beast'),
 (5300771,@BEAST,0,0,1,0,0,1,1,0,5213,-3330,1643.66,4.6,300,0,0,1,0,0,0,0,0,'',0,0,'Horde1 Beast'),
 (5300772,@BEAST,0,0,1,0,0,1,1,0,5210,-3338,1643.66,4.6,300,0,0,1,0,0,0,0,0,'',0,0,'Horde1 Beast'),
 (5300773,@HIPPO,0,0,1,0,0,1,1,0,5216,-3333,1643.66,4.6,300,0,0,1,0,0,0,0,0,'',0,0,'Horde1 Hippo'),
 (5300774,@HIPPO,0,0,1,0,0,1,1,0,5212,-3326,1643.66,4.6,300,0,0,1,0,0,0,0,0,'',0,0,'Horde1 Hippo');

-- Horde wave 2 @ WP2 + Mini-Boss 1
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300780,@BEAST,0,0,1,0,0,1,1,0,5252,-3546,1594.14,1.9,300,0,0,1,0,0,0,0,0,'',0,0,'Horde2 Beast'),
 (5300781,@BEAST,0,0,1,0,0,1,1,0,5262,-3546,1594.14,1.9,300,0,0,1,0,0,0,0,0,'',0,0,'Horde2 Beast'),
 (5300782,@BEAST,0,0,1,0,0,1,1,0,5258,-3556,1594.14,1.9,300,0,0,1,0,0,0,0,0,'',0,0,'Horde2 Beast'),
 (5300783,@HIPPO,0,0,1,0,0,1,1,0,5250,-3554,1594.14,1.9,300,0,0,1,0,0,0,0,0,'',0,0,'Horde2 Hippo'),
 (5300784,@HIPPO,0,0,1,0,0,1,1,0,5264,-3553,1594.14,1.9,300,0,0,1,0,0,0,0,0,'',0,0,'Horde2 Hippo'),
 (5300761,@MB1,0,0,1,0,0,1,1,0,5257.20,-3550.24,1594.14,1.94,600,0,0,1,0,0,0,0,0,'',0,0,'Mini-Boss Naralassa (WP2)');

-- Horde wave 3 @ WP3 + Mini-Boss 2
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300790,@BEAST,0,0,1,0,0,1,1,0,5380,-3694,1593.94,2.8,300,0,0,1,0,0,0,0,0,'',0,0,'Horde3 Beast'),
 (5300791,@BEAST,0,0,1,0,0,1,1,0,5390,-3694,1593.94,2.8,300,0,0,1,0,0,0,0,0,'',0,0,'Horde3 Beast'),
 (5300792,@HIPPO,0,0,1,0,0,1,1,0,5378,-3701,1593.94,2.8,300,0,0,1,0,0,0,0,0,'',0,0,'Horde3 Hippo'),
 (5300793,@HIPPO,0,0,1,0,0,1,1,0,5392,-3701,1593.94,2.8,300,0,0,1,0,0,0,0,0,'',0,0,'Horde3 Hippo'),
 (5300762,@MB2,0,0,1,0,0,1,1,0,5384.95,-3697.66,1593.94,2.84,600,0,0,1,0,0,0,0,0,'',0,0,'Mini-Boss Gnarl (WP3)');

-- ===================== QUESTS =====================
-- Q2: Der verdorbene Pfad (travel: Ysera -> Hueter)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`QuestCompletionLog`)
VALUES (@Q2,2,80,80,0,50000,0,'Der verdorbene Pfad',
 'Der Albtraum quillt aus dem Tal tief unter Nordrassil empor, $N. Steige den Pfad hinab und finde den Hueter des Pfades. Er bewacht den Abstieg in das verdorbene Herz von Hyjal und wird dir den Weg weisen.',
 'Sprich mit dem Hueter des Pfades am Beginn des Abstiegs.');
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q2,@Q1);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@YSERA,@Q2);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@HUETER,@Q2);

-- Q3: Die Brut des Albtraums (kill 8 Beasts + 6 Hippos)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`)
VALUES (@Q3,2,80,80,0,400000,0,'Die Brut des Albtraums',
 'Der Pfad hinab wimmelt von den Kreaturen des Albtraums, $N. Erschlage 8 Albtraum-Bestien und 6 Verdorbene Hippogryphen und kaempfe dir den Weg ins Tal frei.',
 'Albtraum-Bestien erschlagen',@BEAST,10,'Verdorbene Hippogryphen erschlagen',@HIPPO,7);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q3,@Q2);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@HUETER,@Q3);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@HUETER,@Q3);

-- Q4: Waechter des Albtraums (kill 2 mini-bosses)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`)
VALUES (@Q4,2,80,80,0,600000,0,'Waechter des Albtraums',
 'Zwei maechtige Waechter versperren den letzten Abschnitt des Abstiegs. Bezwinge Naralassa, die Traumweberin, und Gnarl, den Albtraum-Waechter. Erst dann steht dir der Weg zum Talboden offen, $N.',
 'Naralassa bezwungen',@MB1,1,'Gnarl bezwungen',@MB2,1);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q4,@Q3);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@HUETER,@Q4);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@HUETER,@Q4);

-- Q5: Der Albtraum-Lord (existing 990021) — re-link to end of gauntlet; start Hueter, end Ysera
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q5,@Q4);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@HUETER,@Q5);
INSERT INTO `creature_questender`   (`id`,`quest`) VALUES (@YSERA,@Q5);

-- Horde wave 4 @ WP4 (final approach to Lord arena)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300800,@BEAST,0,0,1,0,0,1,1,0,5528,-3702,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Beast"),
 (5300801,@BEAST,0,0,1,0,0,1,1,0,5538,-3702,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Beast"),
 (5300802,@BEAST,0,0,1,0,0,1,1,0,5530,-3711,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Beast"),
 (5300803,@BEAST,0,0,1,0,0,1,1,0,5540,-3710,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Beast"),
 (5300804,@HIPPO,0,0,1,0,0,1,1,0,5524,-3705,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Hippo"),
 (5300805,@HIPPO,0,0,1,0,0,1,1,0,5544,-3705,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Hippo"),
 (5300806,@HIPPO,0,0,1,0,0,1,1,0,5533,-3698,1597.5,1.07,300,0,0,1,0,0,0,0,0,"",0,0,"Horde4 Hippo");

-- Horde wave 5 @ WP5 (gate pack at the mouth of the Lord arena)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300810,@BEAST,0,0,1,0,0,1,1,0,5613,-3485,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Beast"),
 (5300811,@BEAST,0,0,1,0,0,1,1,0,5623,-3485,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Beast"),
 (5300812,@BEAST,0,0,1,0,0,1,1,0,5615,-3494,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Beast"),
 (5300813,@BEAST,0,0,1,0,0,1,1,0,5625,-3494,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Beast"),
 (5300814,@HIPPO,0,0,1,0,0,1,1,0,5609,-3489,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Hippo"),
 (5300815,@HIPPO,0,0,1,0,0,1,1,0,5629,-3489,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Hippo"),
 (5300816,@HIPPO,0,0,1,0,0,1,1,0,5618,-3482,1583.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Horde5 Hippo");

-- Scatter mobs BETWEEN waypoints (fill the descent; Z interpolated + biased high so they snap to navmesh on pull)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300820,@BEAST,0,0,1,0,0,1,1,0,5300,-3599,1595.5,1.9,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter B"),
 (5300821,@HIPPO,0,0,1,0,0,1,1,0,5321,-3624,1595.5,1.9,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter B"),
 (5300822,@BEAST,0,0,1,0,0,1,1,0,5342,-3649,1595.5,1.9,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter B"),
 (5300823,@BEAST,0,0,1,0,0,1,1,0,5435,-3700,1596.5,0.0,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter C"),
 (5300824,@HIPPO,0,0,1,0,0,1,1,0,5485,-3703,1598.5,0.0,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter C"),
 (5300825,@BEAST,0,0,1,0,0,1,1,0,5561,-3634,1594.0,1.2,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter D"),
 (5300826,@HIPPO,0,0,1,0,0,1,1,0,5590,-3562,1587.0,1.2,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter D"),
 (5300827,@BEAST,0,0,1,0,0,1,1,0,5649,-3453,1588.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter E"),
 (5300828,@HIPPO,0,0,1,0,0,1,1,0,5680,-3415,1592.0,0.87,300,0,0,1,0,0,0,0,0,"",0,0,"Scatter E");
