-- Hyjal Arc S2: The Twisted Glade. enUS. Solo/small-group questing tier. Idempotent.
-- Lore: A pocket of the Emerald Nightmare has bled into the eastern shelf of Nordrassil.
-- Satyrs of the Twistshade brood and the corrupted beasts of the Glade roam free,
-- centered on a withered Ancient. Sentinel Maevra holds the line and needs help.
SET @HUB:=990076; SET @SATYR:=990077; SET @BEAST:=990078; SET @BOSS:=990079;
SET @Q1:=990061; SET @Q2:=990062;

DELETE FROM `creature` WHERE `id1` IN (@HUB,@SATYR,@BEAST,@BOSS);
DELETE FROM `creature_queststarter` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `creature_questender` WHERE `quest` IN (@Q1,@Q2);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_request_items` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template_addon` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `quest_template` WHERE `ID` IN (@Q1,@Q2);
DELETE FROM `event_worldbosses` WHERE `entry`=@BOSS;
DELETE FROM `creature_text` WHERE `CreatureID`=@BOSS;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@BOSS AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@HUB,@SATYR,@BEAST,@BOSS);
DELETE FROM `creature_template` WHERE `entry` IN (@HUB,@SATYR,@BEAST,@BOSS);

-- Sentinel Maevra (quest hub, immune, faction 35). Night-elf female display.
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@HUB,'Sentinel Maevra','Sentinels of Hyjal',80,80,35,3,1,768,7,'',0,50,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@HUB,0,11603,1.0,1,0);

-- Twistshade Satyr (hostile trash, satyr display)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@SATYR,'Twistshade Satyr','',80,80,14,0,1,0,7,'',0,5,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@SATYR,0,15214,1.0,1,0);

-- Nightmare Bristlepelt (hostile beast, type=1 beast)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`) VALUES
 (@BEAST,'Nightmare Bristlepelt','',80,80,14,0,1,0,1,'',0,4,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@BEAST,0,12821,1.0,1,0);

-- Xan'thrazil the Withered (mini-boss, rank=2 elite, SmartAI). Ancient-of-War display, slightly larger.
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`rank`) VALUES
 (@BOSS,'Xan''thrazil the Withered','Heart of the Glade',80,80,14,0,1,0,7,'SmartAI',0,55,1,1,1,2);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@BOSS,0,7665,1.2,1,0);

INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@BOSS,0,0,'The Dream rots... and the rot drinks deep!',14,0,100,0,0,0,0,0,'Xan''thrazil aggro'),
 (@BOSS,1,0,'The Glade... slips... back into shadow...',14,0,100,0,0,0,0,0,'Xan''thrazil death');

INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`target_type`,`target_param1`,`comment`) VALUES
 (@BOSS,0,0,0,4,0,100,0,0,0,0,0,1,0,1,0,'Xan''thrazil aggro yell'),
 (@BOSS,0,1,0,0,0,100,0,4000,7000,9000,12000,11,33908,2,0,'Xan''thrazil Moonfire on victim'),
 (@BOSS,0,2,0,0,0,100,0,12000,18000,18000,24000,11,8281,5,0,'Xan''thrazil Sand Storm AoE'),
 (@BOSS,0,3,0,2,0,100,0,0,25,0,0,11,8599,1,0,'Xan''thrazil Enrage <25%'),
 (@BOSS,0,4,0,6,0,100,0,0,0,0,0,1,1,1,0,'Xan''thrazil death yell');

INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`) VALUES (@BOSS,0,3);

-- Quest 1: Roots of the Withering (kill 8 satyrs + 6 bristlepelts)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`) VALUES
 (@Q1,2,80,80,300000,0,'Roots of the Withering',
  'The Twistshade come crawling from the Glade in numbers, $N, and the bristlepelts that once shepherded these woods have turned hollow-eyed and feral. Cull eight of the satyrs and six of the corrupted beasts before the rot spreads further into the Sentinels'' line.',
  'Twistshade Satyrs slain',@SATYR,8,'Nightmare Bristlepelts slain',@BEAST,6);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q1,0);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q1,'The Glade breathes a little easier, $N. But the rot has a heart - and until it stops beating, this will never end.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q1,'The Twistshade and the bristlepelts still hold the Glade, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@HUB,@Q1);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@HUB,@Q1);

-- Quest 2: Cut the Withered Heart (kill Xan'thrazil)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`) VALUES
 (@Q2,2,80,80,500000,0,'Cut the Withered Heart',
  'At the center of the Glade stands what was once an Ancient - now Xan''thrazil, host to the rot itself. Strike the heart, $N. End it before it spreads back to Nordrassil.',
  'Xan''thrazil the Withered slain',@BOSS,1);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q2,@Q1);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q2,'Xan''thrazil falls and the Glade quiets at last. The Sentinels owe you a debt, $N - and a new shoot may grow where the rot once stood.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q2,'Xan''thrazil still poisons the Glade, $N.');
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@HUB,@Q2);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@HUB,@Q2);

-- Spawns (Map 1, eastern Nordrassil shelf — close to hub elevation z=1650)
-- guid block 5301450-5301475 (5301400/5301402 taken by 990200/990201 portal wardens)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301450,@HUB ,0,0,1,0,0,1,1,0,5430.000,-3320.000,1650.000,4.50,300,0,0,1,0,0,0,0,0,'',0,0,'SentinelMaevra'),
 (5301451,@BOSS,0,0,1,0,0,1,1,0,5470.000,-3290.000,1650.000,3.80,300,0,0,1,0,0,0,0,0,'',0,0,'XanthrazilTheWithered'),
 -- Twistshade Satyrs (8)
 (5301460,@SATYR,0,0,1,0,0,1,1,0,5440.000,-3275.000,1650.000,1.00,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301461,@SATYR,0,0,1,0,0,1,1,0,5448.000,-3268.000,1650.000,1.50,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301462,@SATYR,0,0,1,0,0,1,1,0,5456.000,-3282.000,1650.000,2.20,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301463,@SATYR,0,0,1,0,0,1,1,0,5462.000,-3270.000,1650.000,0.80,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301464,@SATYR,0,0,1,0,0,1,1,0,5478.000,-3275.000,1650.000,1.20,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301465,@SATYR,0,0,1,0,0,1,1,0,5485.000,-3290.000,1650.000,3.10,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301466,@SATYR,0,0,1,0,0,1,1,0,5468.000,-3305.000,1650.000,4.00,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 (5301467,@SATYR,0,0,1,0,0,1,1,0,5452.000,-3300.000,1650.000,5.40,300,0,0,1,0,0,0,0,0,'',0,0,'satyr'),
 -- Nightmare Bristlepelts (6)
 (5301470,@BEAST,0,0,1,0,0,1,1,0,5405.000,-3260.000,1650.000,1.80,300,0,0,1,0,0,0,0,0,'',0,0,'beast'),
 (5301471,@BEAST,0,0,1,0,0,1,1,0,5418.000,-3252.000,1650.000,2.10,300,0,0,1,0,0,0,0,0,'',0,0,'beast'),
 (5301472,@BEAST,0,0,1,0,0,1,1,0,5430.000,-3258.000,1650.000,2.50,300,0,0,1,0,0,0,0,0,'',0,0,'beast'),
 (5301473,@BEAST,0,0,1,0,0,1,1,0,5410.000,-3290.000,1650.000,0.30,300,0,0,1,0,0,0,0,0,'',0,0,'beast'),
 (5301474,@BEAST,0,0,1,0,0,1,1,0,5395.000,-3300.000,1650.000,0.70,300,0,0,1,0,0,0,0,0,'',0,0,'beast'),
 (5301475,@BEAST,0,0,1,0,0,1,1,0,5422.000,-3286.000,1650.000,5.80,300,0,0,1,0,0,0,0,0,'',0,0,'beast');
