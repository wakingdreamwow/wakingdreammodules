-- Emerald Dream Stage 3: Albtraum-Lord endboss + follow-up quest (after 990020). Idempotent. Hyjal hub (map 1).
SET @LORD:=990014; SET @YSERA:=990011; SET @Q2:=990021; SET @Q1:=990020;

DELETE FROM `creature_queststarter` WHERE `quest`=@Q2;
DELETE FROM `creature_questender` WHERE `quest`=@Q2;
DELETE FROM `quest_template` WHERE `ID`=@Q2;
DELETE FROM `quest_template_addon` WHERE `ID`=@Q2;
DELETE FROM `event_worldbosses` WHERE `entry`=@LORD;
DELETE FROM `creature` WHERE `id1`=@LORD;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@LORD AND `source_type`=0;
DELETE FROM `creature_text` WHERE `CreatureID`=@LORD;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@LORD;
DELETE FROM `creature_template` WHERE `entry`=@LORD;

-- Albtraum-Lord (lvl80 worldboss, dragonkin, SmartAI, ~1.5M HP)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`)
VALUES (@LORD,'Albtraum-Lord','Tyrann des verdorbenen Traums',80,80,14,0,1,0,2,'SmartAI',0,280,1,1,1,3);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@LORD,0,8570,1.6,1,0);

INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@LORD,0,0,'Der Traum gehoert nun dem Albtraum! Du kommst gerade recht, um zu zerbrechen.',14,0,100,0,0,0,0,0,'Lord aggro'),
 (@LORD,1,0,'Der Albtraum... waehrt... ewig...',14,0,100,0,0,0,0,0,'Lord death');

-- SmartAI: aggro yell, Noxious Breath, AoE, Enrage<25%, death yell
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
 (@LORD,0,0,1,4,0,100,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Lord aggro yell'),
 (@LORD,0,1,0,0,0,100,0,6000,11000,9000,14000,0,0,11,24818,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Lord Noxious Breath'),
 (@LORD,0,2,0,0,0,100,0,12000,18000,15000,22000,0,0,11,66813,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Lord AoE'),
 (@LORD,0,3,0,2,0,100,0,0,25,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Lord Enrage <25%'),
 (@LORD,0,4,0,6,0,100,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Lord death yell');

-- Spawn at the Hyjal dream hub (valid ground, within shade cluster bounds)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300950,@LORD,0,0,1,0,0,1,1,0,5711.07,-3377.77,1593.39,3.4,300,0,0,1500000,0,0,0,0,0,'',0,0,'Albtraum-Lord');

-- Loot via worldboss personal-loot system (epic, lvl80 -> level-80 gear)
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`) VALUES (@LORD,1,4);

-- Quest: Der Albtraum-Lord (after 990020, kill the Lord)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`)
VALUES (@Q2,2,80,80,0,800000,0,'Der Albtraum-Lord',
 'Die Schemen waren nur Vorboten, $N. Im Herzen des verdorbenen Hains thront der Albtraum-Lord selbst. Erschlage ihn und befreie den Smaragdtraum von seiner Schreckensherrschaft.',
 'Albtraum-Lord erschlagen',@LORD,1);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q2,@Q1);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@YSERA,@Q2);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@YSERA,@Q2);
