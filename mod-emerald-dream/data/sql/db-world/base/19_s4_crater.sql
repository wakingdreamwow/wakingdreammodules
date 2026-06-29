-- Hyjal Arc S4: The Crater - Scar of Archimonde. enUS. Solo/small-group. Idempotent.
SET @WATCH:=990068; SET @HOUND:=990069; SET @INF:=990070; SET @BOSS:=990071; SET @Q1:=990057; SET @Q2:=990058;
DELETE FROM `creature` WHERE `id1` IN (@WATCH,@HOUND,@INF,@BOSS);
DELETE FROM `creature_queststarter` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `creature_questender` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_request_items` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template_addon` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `event_worldbosses` WHERE `entry`=@BOSS;
DELETE FROM `creature_text` WHERE `CreatureID`=@BOSS;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@BOSS AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@WATCH,@HOUND,@INF,@BOSS);
DELETE FROM `creature_template` WHERE `entry` IN (@WATCH,@HOUND,@INF,@BOSS);

INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@WATCH,'Keeper Ordanus','Watcher of the Scar',80,80,35,3,1,768,7,'',0,50,1,1,1),
 (@HOUND,'Scarbound Felhound','',80,80,14,0,1,0,7,'',0,5,1,1,1),
 (@INF,'Lingering Infernal','',80,80,14,0,1,0,7,'',0,7,1,1,1);
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`) VALUES
 (@BOSS,'Doomcaller Vextroth','Echo of the Legion',80,80,14,0,1,0,7,'SmartAI',0,55,1,1,1,2);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES
 (@WATCH,0,4249,1.0,1,0),(@HOUND,0,1913,1.0,1,0),(@INF,0,169,1.0,1,0),(@BOSS,0,4426,1.1,1,0);
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@BOSS,0,0,'The Legion never truly left this place!',14,0,100,0,0,0,0,0,'Vextroth aggro'),
 (@BOSS,1,0,'Archimonde... avenged...',14,0,100,0,0,0,0,0,'Vextroth death');
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`target_type`,`target_param1`,`comment`) VALUES
 (@BOSS,0,0,0,4,0,100,0,0,0,0,0,1,0,1,0,'Vextroth aggro yell'),
 (@BOSS,0,1,0,0,0,100,0,3000,5000,4000,6000,11,686,2,0,'Vextroth Shadow Bolt on victim'),
 (@BOSS,0,2,0,2,0,100,0,0,25,0,0,11,8599,1,0,'Vextroth Enrage <25%'),
 (@BOSS,0,3,0,6,0,100,0,0,0,0,0,1,1,1,0,'Vextroth death yell');
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`) VALUES (@BOSS,0,3);

INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`) VALUES
 (@Q1,2,80,80,300000,0,'Embers of the Legion',
  'Long ago Archimonde fell here, and the Burning Legion left a scar that never healed. Demons still gather in the crater, $N. Burn them out: destroy 8 Scarbound Felhounds and 5 Lingering Infernals.',
  'Scarbound Felhounds destroyed',@HOUND,8,'Lingering Infernals destroyed',@INF,5);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q1,0);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q1,'The crater quiets, $N - but a darker will stirs the embers. A commander of the old Legion still lingers here.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q1,'The demons still gather in the scar, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@WATCH,@Q1);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@WATCH,@Q1);

INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`) VALUES
 (@Q2,2,80,80,500000,0,'The Doomcaller',
  'Doomcaller Vextroth marshals the demons of the scar - an echo of the host that once besieged Nordrassil. End him, $N, and lay the Legion''s shadow to rest at last.',
  'Doomcaller Vextroth slain',@BOSS,1);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q2,@Q1);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q2,'Vextroth is undone and the scar grows still. The fallen of Hyjal rest a little easier tonight, $N.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q2,'Vextroth still commands the crater, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@WATCH,@Q2);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@WATCH,@Q2);
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301330,990068,0,0,1,0,0,1,1,0,5430.000,-2860.000,1468.819,4.70,300,0,0,1,0,0,0,0,0,'',0,0,'watcher');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301331,990071,0,0,1,0,0,1,1,0,5430.000,-2806.000,1463.575,1.50,300,0,0,1,0,0,0,0,0,'',0,0,'boss');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301340,990069,0,0,1,0,0,1,1,0,5395.000,-2792.000,1461.924,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301341,990069,0,0,1,0,0,1,1,0,5405.000,-2820.000,1465.151,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301342,990069,0,0,1,0,0,1,1,0,5418.000,-2835.000,1466.014,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301343,990069,0,0,1,0,0,1,1,0,5448.000,-2832.000,1465.995,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301344,990069,0,0,1,0,0,1,1,0,5462.000,-2818.000,1465.110,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301345,990069,0,0,1,0,0,1,1,0,5455.000,-2788.000,1461.415,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301346,990069,0,0,1,0,0,1,1,0,5410.000,-2778.000,1460.415,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301347,990069,0,0,1,0,0,1,1,0,5440.000,-2770.000,1459.553,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'hound');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301350,990070,0,0,1,0,0,1,1,0,5420.000,-2800.000,1463.030,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'inf');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301351,990070,0,0,1,0,0,1,1,0,5445.000,-2812.000,1464.154,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'inf');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301352,990070,0,0,1,0,0,1,1,0,5432.000,-2822.000,1464.895,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'inf');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301353,990070,0,0,1,0,0,1,1,0,5408.000,-2810.000,1464.118,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'inf');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301354,990070,0,0,1,0,0,1,1,0,5455.000,-2800.000,1462.890,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'inf');
