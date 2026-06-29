-- RaidFill NPC "Schlachtzugs-Organisator" (entry 990050) at all PvE raid entrances (Northrend, map 571)
DELETE FROM `creature_template` WHERE `entry`=990050;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`gossip_menu_id`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`ScriptName`,`RegenHealth`) VALUES
(990050,'Raid Organizer','Reinforcements',0,80,80,35,1,1,768,7,'','npc_raid_commander',1);

DELETE FROM `creature_template_model` WHERE `CreatureID`=990050;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`) VALUES
(990050,0,7330,1,1);

DELETE FROM `creature` WHERE `id1`=990050;
INSERT INTO `creature`
(`guid`,`id1`,`map`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`MovementType`,`Comment`) VALUES
(5300750,990050,571,1,1,5873.8,2111,636,0,300,0,'RaidFill ICC'),
(5300751,990050,571,1,1,3668.7,-1262.5,243.6,0,300,0,'RaidFill Naxxramas'),
(5300752,990050,571,1,1,9327.2,-1114.6,1245.2,0,300,0,'RaidFill Ulduar'),
(5300753,990050,571,1,1,8515.7,717,558.2,0,300,0,'RaidFill ToC'),
(5300754,990050,571,1,1,5453.7,2840.8,421.3,0,300,0,'RaidFill VoA'),
(5300755,990050,571,1,1,3457.1,262.4,-113.8,0,300,0,'RaidFill ObsidianSanctum'),
(5300756,990050,571,1,1,3859.4,6989.9,152,0,300,0,'RaidFill EyeOfEternity');
