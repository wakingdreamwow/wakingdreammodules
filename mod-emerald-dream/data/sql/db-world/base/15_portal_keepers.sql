-- Hyjal entry: Portalwaechter NPC at each dragon shrine portal (gossip-teleport gated by attunement 990054). Idempotent.
SET @KEEPER:=990061; SET @MENU:=60101; SET @Q:=990054;

DELETE FROM `creature` WHERE `id1`=@KEEPER;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@KEEPER AND `source_type`=0;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=@MENU;
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@MENU;
DELETE FROM `gossip_menu` WHERE `MenuID`=@MENU;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@KEEPER;
DELETE FROM `creature_template` WHERE `entry`=@KEEPER;

INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`gossip_menu_id`)
VALUES (@KEEPER,'Hueter des Traum-Portals','Smaragdschwarm',80,80,35,1,1,768,7,'SmartAI',0,50,1,1,1,@MENU);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@KEEPER,0,11906,1.0,1,0);

INSERT INTO `gossip_menu` (`MenuID`,`TextID`) VALUES (@MENU,1);
INSERT INTO `gossip_menu_option` (`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`) VALUES (@MENU,1,2,'Tritt durch das Portal nach Hyjal.',1,1);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
VALUES (15,@MENU,1,0,0,8,0,@Q,0,0,0,0,0,'','Hyjal portal: only if attunement 990054 rewarded');

INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES (@KEEPER,0,0,0,62,0,100,0,@MENU,1,0,0,62,1,0,0,0,0,0,7,0,0,0,0,5373,-3379,1656,0,'Portal keeper: gossip select -> teleport to Nordrassil summit');

-- Spawn at Taerar portal (Twilight Grove, map 0) — exact coords (WMO platform, NOT sampler)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301280,@KEEPER,0,0,0,0,0,1,1,0,-10364.507,-421.520,63.621,6.27,300,0,0,1,0,0,0,0,0,'',0,0,'Portalwaechter Taerar');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301281,990061,0,0,0,0,0,1,1,0,869.689,-3974.069,145.827,0.361,300,0,0,1,0,0,0,0,0,"",0,0,"Portalwaechter Lethon");
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301282,990061,0,0,1,0,0,1,1,0,3297.308,-3729.400,173.462,5.98,300,0,0,1,0,0,0,0,0,"",0,0,"Portalwaechter Ysondre");
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (5301283,990061,0,0,1,0,0,1,1,0,-2864.084,1879.023,52.648,5.855,300,0,0,1,0,0,0,0,0,"",0,0,"Portalwaechter Emeriss");
