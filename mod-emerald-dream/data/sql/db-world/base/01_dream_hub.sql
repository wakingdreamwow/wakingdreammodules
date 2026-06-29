-- Emerald Dream Stage 2: Ysera questgiver + opening quest + nightmare trash.
-- Relocated to Nordrassil (Hyjal, map 1) — map 169 has no terrain. Idempotent.
SET @YSERA:=990011; SET @MOB:=990012; SET @Q:=990020;

DELETE FROM `creature` WHERE `id1` IN (@YSERA,@MOB);
DELETE FROM `creature_queststarter` WHERE `quest`=@Q;
DELETE FROM `creature_questender` WHERE `quest`=@Q;
DELETE FROM `quest_template` WHERE `ID`=@Q;
DELETE FROM `creature_text` WHERE `CreatureID`=@YSERA;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@YSERA AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@YSERA,@MOB);
DELETE FROM `creature_template` WHERE `entry` IN (@YSERA,@MOB);

-- Ysera (questgiver, gossip+quest, immune, SmartAI for greeting)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@YSERA,'Ysera','Hueterin der Traeume',80,80,35,3,1,768,2,'SmartAI',0,100,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@YSERA,0,24808,1,1,0);

-- Albtraum-Schemen (hostile trash, lvl80)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@MOB,'Albtraum-Schemen','',80,80,14,0,1,0,6,'',0,1,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@MOB,0,10553,1,1,0);

-- Greeting monologue (yell)
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
 (@YSERA,0,0,'Endlich... ein Sterblicher mutig genug, den Traum zu betreten.',1,0,100,0,0,0,0,0,'Ysera 1'),
 (@YSERA,0,1,'Der Smaragdtraum verdirbt. Der Albtraum frisst sich durch das Gewebe der Welt.',1,0,100,0,0,0,0,0,'Ysera 2'),
 (@YSERA,0,2,'Hilf mir, Held - oder alles Lebende wird im Albtraum ertrinken.',1,0,100,0,0,0,0,0,'Ysera 3');

-- SmartAI: greet on seeing a (friendly) player, long cooldown
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES (@YSERA,0,0,0,10,0,100,0,1,25,300000,300000,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Ysera greets on LOS');

-- Quest: Schatten ueber dem Smaragdtraum (kill 8 Albtraum-Schemen)
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`)
VALUES (@Q,2,80,80,0,250000,0,'Schatten ueber dem Smaragdtraum',
 'Der Albtraum sickert in den Traum. Vernichte 8 Albtraum-Schemen rund um die Lichtung und schwaeche den Griff des Albtraums, $N.',
 'Albtraum-Schemen vernichtet',@MOB,8);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@YSERA,@Q);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@YSERA,@Q);

-- Spawns: Ysera at Nordrassil hub + 8 nightmare shades clustered nearby (Hyjal, map 1, z~1655.5)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5300682,@YSERA,0,0,1,0,0,1,1,0,5379,-3386,1655.5,0.6,300,0,0,100000,0,0,0,0,0,'',0,0,'Ysera Hub'),
 (5300683,@MOB,0,0,1,0,0,1,1,0,5355,-3360,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300684,@MOB,0,0,1,0,0,1,1,0,5362,-3352,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300685,@MOB,0,0,1,0,0,1,1,0,5348,-3366,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300686,@MOB,0,0,1,0,0,1,1,0,5390,-3360,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300687,@MOB,0,0,1,0,0,1,1,0,5396,-3372,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300688,@MOB,0,0,1,0,0,1,1,0,5358,-3396,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300689,@MOB,0,0,1,0,0,1,1,0,5384,-3402,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade'),
 (5300690,@MOB,0,0,1,0,0,1,1,0,5400,-3388,1655.5,3.1,300,3,0,1,0,1,0,0,0,'',0,0,'Shade');
