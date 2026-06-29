-- Hyjal Arc S5: The Smouldering Deep (Twilight + fire from the Hyjal caves). enUS. Solo/small-group. Idempotent.
SET @WATCH:=990072; SET @CULT:=990073; SET @ELEM:=990074; SET @BOSS:=990075; SET @Q1:=990059; SET @Q2:=990060;
DELETE FROM `creature` WHERE `id1` IN (@WATCH,@CULT,@ELEM,@BOSS);
DELETE FROM `creature_queststarter` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `creature_questender` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_request_items` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template_addon` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `event_worldbosses` WHERE `entry`=@BOSS;
DELETE FROM `creature_text` WHERE `CreatureID`=@BOSS;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@BOSS AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@WATCH,@CULT,@ELEM,@BOSS);
DELETE FROM `creature_template` WHERE `entry` IN (@WATCH,@CULT,@ELEM,@BOSS);

INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@WATCH,'Warden Thessaly','Sentinels of Hyjal',80,80,35,3,1,768,7,'',0,50,1,1,1),
 (@CULT,'Twilight Firebrand','',80,80,14,0,1,0,7,'',0,5,1,1,1),
 (@ELEM,'Cinder Elemental','',80,80,14,0,1,0,8,'',0,6,1,1,1);
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`) VALUES
 (@BOSS,'Pyrelord Cindraxis','The Fire Below',80,80,14,0,1,0,8,'SmartAI',0,55,1,1,1,2);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES
 (@WATCH,0,4249,1.0,1,0),(@CULT,0,7825,1.0,1,0),(@ELEM,0,12239,1.0,1,0),(@BOSS,0,12162,1.2,1,0);
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@BOSS,0,0,'From the deep, we burn the World Tree to its roots!',14,0,100,0,0,0,0,0,'Cindraxis aggro'),
 (@BOSS,1,0,'The fire... gutters...',14,0,100,0,0,0,0,0,'Cindraxis death');
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`target_type`,`target_param1`,`comment`) VALUES
 (@BOSS,0,0,0,4,0,100,0,0,0,0,0,1,0,1,0,'Cindraxis aggro yell'),
 (@BOSS,0,1,0,0,0,100,0,3000,5000,4000,6000,11,8050,2,0,'Cindraxis Flame Shock on victim'),
 (@BOSS,0,2,0,2,0,100,0,0,25,0,0,11,8599,1,0,'Cindraxis Enrage <25%'),
 (@BOSS,0,3,0,6,0,100,0,0,0,0,0,1,1,1,0,'Cindraxis death yell');
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`) VALUES (@BOSS,0,3);

INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`) VALUES
 (@Q1,2,80,80,300000,0,'The Fire Below',
  'The Twilight''s Hammer has bored into the roots of Hyjal, and fire pours up from the deep to choke the Well and the World Tree. Throw them back, $N: slay 8 Twilight Firebrands and 5 Cinder Elementals at the cave mouth.',
  'Twilight Firebrands slain',@CULT,8,'Cinder Elementals extinguished',@ELEM,5);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q1,0);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q1,'The cave mouth cools, $N - but something vast and burning stirs in the dark below. Their lord has come.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q1,'The fire still pours from the deep, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@WATCH,@Q1);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@WATCH,@Q1);

INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`) VALUES
 (@Q2,2,80,80,500000,0,'Pyrelord Cindraxis',
  'Pyrelord Cindraxis leads the incursion from below - a living furnace bent on burning Nordrassil to ash. Quench him, $N, and seal the fire in the deep.',
  'Pyrelord Cindraxis slain',@BOSS,1);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q2,@Q1);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q2,'Cindraxis is quenched and the deep falls dark. Three fronts held - the World Tree still stands, thanks to you, $N.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q2,'Cindraxis still burns below, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@WATCH,@Q2);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@WATCH,@Q2);
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301360,990072,0,0,1,0,0,1,1,0,4805.000,-1725.000,1151.970,4.50,300,0,0,1,0,0,0,0,0,'',0,0,'watcher');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301361,990075,0,0,1,0,0,1,1,0,4815.000,-1758.000,1156.964,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'boss');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301370,990073,0,0,1,0,0,1,1,0,4795.000,-1735.000,1150.833,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301371,990073,0,0,1,0,0,1,1,0,4808.000,-1745.000,1154.856,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301372,990073,0,0,1,0,0,1,1,0,4820.000,-1768.000,1161.678,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301373,990073,0,0,1,0,0,1,1,0,4800.000,-1775.000,1182.712,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301374,990073,0,0,1,0,0,1,1,0,4790.000,-1758.000,1156.662,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301375,990073,0,0,1,0,0,1,1,0,4812.000,-1730.000,1154.122,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301376,990073,0,0,1,0,0,1,1,0,4825.000,-1748.000,1155.965,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301377,990073,0,0,1,0,0,1,1,0,4798.000,-1788.000,1179.463,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'cult');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301380,990074,0,0,1,0,0,1,1,0,4810.000,-1762.000,1159.629,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'elem');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301381,990074,0,0,1,0,0,1,1,0,4822.000,-1755.000,1155.990,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'elem');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301382,990074,0,0,1,0,0,1,1,0,4802.000,-1750.000,1156.065,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'elem');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301383,990074,0,0,1,0,0,1,1,0,4818.000,-1772.000,1165.162,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'elem');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301384,990074,0,0,1,0,0,1,1,0,4793.000,-1745.000,1150.194,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'elem');
