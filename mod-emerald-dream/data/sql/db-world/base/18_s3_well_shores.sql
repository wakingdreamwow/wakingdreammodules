-- Hyjal Arc S3: Shores of the Well of Eternity. enUS. Solo/small-group questing tier. Idempotent.
SET @WARDEN:=990064; SET @NAGA:=990065; SET @GHOST:=990066; SET @BOSS:=990067;
SET @Q1:=990055; SET @Q2:=990056;

DELETE FROM `creature` WHERE `id1` IN (@WARDEN,@NAGA,@GHOST,@BOSS);
DELETE FROM `creature_queststarter` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `creature_questender` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_request_items` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template_addon` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `event_worldbosses` WHERE `entry`=@BOSS;
DELETE FROM `creature_text` WHERE `CreatureID`=@BOSS;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@BOSS AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@WARDEN,@NAGA,@GHOST,@BOSS);
DELETE FROM `creature_template` WHERE `entry` IN (@WARDEN,@NAGA,@GHOST,@BOSS);

-- Warden (quest hub, immune)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@WARDEN,'Warden Senara','Sentinels of Hyjal',80,80,35,3,1,768,7,'',0,50,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@WARDEN,0,4249,1.0,1,0);
-- Spitelash Naga (shore trash)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@NAGA,'Spitelash Reaver','',80,80,14,0,1,0,7,'',0,5,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@NAGA,0,6747,1.0,1,0);
-- Restless Highborne (ghost trash)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@GHOST,'Restless Highborne','',80,80,14,0,1,0,6,'',0,4,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@GHOST,0,10702,1.0,1,0);
-- Tidewarden Naxxis (mini-boss, elite naga)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`) VALUES
 (@BOSS,'Tidewarden Naxxis','Spitelash Incursion',80,80,14,0,1,0,7,'SmartAI',0,55,1,1,1,2);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@BOSS,0,18389,1.2,1,0);
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@BOSS,0,0,'The Well belongs to the depths now!',14,0,100,0,0,0,0,0,'Naxxis aggro'),
 (@BOSS,1,0,'The tide... recedes...',14,0,100,0,0,0,0,0,'Naxxis death');
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`target_type`,`target_param1`,`comment`) VALUES
 (@BOSS,0,0,0,4,0,100,0,0,0,0,0,1,0,1,0,'Naxxis aggro yell'),
 (@BOSS,0,1,0,0,0,100,0,3000,5000,4000,6000,11,9672,2,0,'Naxxis Frostbolt on victim'),
 (@BOSS,0,2,0,2,0,100,0,0,25,0,0,11,8599,1,0,'Naxxis Enrage <25%'),
 (@BOSS,0,3,0,6,0,100,0,0,0,0,0,1,1,1,0,'Naxxis death yell');
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`) VALUES (@BOSS,0,3);

-- Quests
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`) VALUES
 (@Q1,2,80,80,300000,0,'Whispers Beneath the Waves',
  'While our strength is spent against the Nightmare, the Well of Eternity lies unguarded. The Spitelash naga have crawled up from the depths and the restless Highborne dead stir along the shore. Drive them back, $N: slay 8 Spitelash Reavers and put 6 Restless Highborne to rest.',
  'Spitelash Reavers slain',@NAGA,8,'Restless Highborne laid to rest',@GHOST,6);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q1,0);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q1,'The shore breathes a little easier, $N. But this was no mere raid - something commands them.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q1,'The naga and the dead still hold the shore, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@WARDEN,@Q1);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@WARDEN,@Q1);

INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`) VALUES
 (@Q2,2,80,80,500000,0,'The Tidewarden',
  'The incursion has a master: Tidewarden Naxxis, who marshals the Spitelash at the water''s edge. Cut off the head of the serpent, $N, and the Well shore is ours once more.',
  'Tidewarden Naxxis slain',@BOSS,1);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q2,@Q1);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q2,'Naxxis is slain and the Spitelash flee to the deep. The Well is safe - for now. You have the gratitude of the Sentinels, $N.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q2,'Naxxis still commands the shore, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@WARDEN,@Q2);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@WARDEN,@Q2);
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301300,990064,0,0,1,0,0,1,1,0,5340.000,-3520.000,1574.038,2.00,300,0,0,1,0,0,0,0,0,'',0,0,'WardenSenara');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301301,990067,0,0,1,0,0,1,1,0,5475.000,-3430.000,1559.696,3.90,300,0,0,1,0,0,0,0,0,'',0,0,'TidewardenNaxxis');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301310,990065,0,0,1,0,0,1,1,0,5398.000,-3468.000,1557.321,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301311,990065,0,0,1,0,0,1,1,0,5405.000,-3475.000,1546.782,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301312,990065,0,0,1,0,0,1,1,0,5400.000,-3598.000,1560.187,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301313,990065,0,0,1,0,0,1,1,0,5408.000,-3604.000,1558.186,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301314,990065,0,0,1,0,0,1,1,0,5472.000,-3438.000,1557.741,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301315,990065,0,0,1,0,0,1,1,0,5482.000,-3428.000,1559.253,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301316,990065,0,0,1,0,0,1,1,0,5558.000,-3472.000,1568.359,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301317,990065,0,0,1,0,0,1,1,0,5562.000,-3466.000,1569.788,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'naga');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301320,990066,0,0,1,0,0,1,1,0,5560.000,-3598.000,1586.296,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'ghost');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301321,990066,0,0,1,0,0,1,1,0,5566.000,-3604.000,1589.770,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'ghost');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301322,990066,0,0,1,0,0,1,1,0,5598.000,-3536.000,1579.974,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'ghost');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301323,990066,0,0,1,0,0,1,1,0,5604.000,-3530.000,1580.540,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'ghost');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301324,990066,0,0,1,0,0,1,1,0,5352.000,-3548.000,1573.303,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'ghost');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301325,990066,0,0,1,0,0,1,1,0,5346.000,-3556.000,1575.362,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'ghost');
