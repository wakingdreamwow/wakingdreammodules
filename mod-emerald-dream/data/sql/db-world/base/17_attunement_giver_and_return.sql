-- Attunement quest-giver (Cenarion Emissary, Moonglade/Nighthaven) + return portal at Nordrassil. enUS only. Idempotent.
SET @EMISSARY:=990062; SET @RETURN:=990063; SET @Q:=990054; SET @RMENU:=60102;

-- ---- Cenarion Emissary: gives + takes attunement quest 990054 ----
DELETE FROM `creature` WHERE `id1`=@EMISSARY;
DELETE FROM `creature_queststarter` WHERE `quest`=@Q;
DELETE FROM `creature_questender` WHERE `quest`=@Q;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@EMISSARY;
DELETE FROM `creature_template` WHERE `entry`=@EMISSARY;
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@EMISSARY,'Cenarion Emissary','Keeper of the Glade',80,80,35,3,1,768,7,'',0,50,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@EMISSARY,0,4249,1.1,1,0);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@EMISSARY,@Q);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@EMISSARY,@Q);
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301290,@EMISSARY,0,0,1,0,0,1,1,0,7805,-2581,489.0,1.5,300,0,0,1,0,0,0,0,0,'',0,0,'Cenarion Emissary (Nighthaven)');

-- ---- Return portal keeper at Nordrassil summit (free exit to Moonglade) ----
DELETE FROM `creature` WHERE `id1`=@RETURN;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@RETURN AND `source_type`=0;
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@RMENU;
DELETE FROM `gossip_menu` WHERE `MenuID`=@RMENU;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@RETURN;
DELETE FROM `creature_template` WHERE `entry`=@RETURN;
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`gossip_menu_id`)
VALUES (@RETURN,'Keeper of the Dream Portal','Green Dragonflight',80,80,35,1,1,768,7,'SmartAI',0,50,1,1,1,@RMENU);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@RETURN,0,11906,1.0,1,0);
INSERT INTO `gossip_menu` (`MenuID`,`TextID`) VALUES (@RMENU,1);
INSERT INTO `gossip_menu_option` (`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`) VALUES (@RMENU,1,2,'Return through the portal to Moonglade.',1,1);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES (@RETURN,0,0,0,62,0,100,0,@RMENU,1,0,0,62,1,0,0,0,0,0,7,0,0,0,0,7805,-2581,489.0,0,'Return keeper: gossip select -> teleport to Moonglade');
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301291,@RETURN,0,0,1,0,0,1,1,0,5377,-3382,1655.5,2.2,300,0,0,1,0,0,0,0,0,'',0,0,'Return portal keeper (Nordrassil)');

-- ---- remove old dev hub return-warden (replaced by lore return keeper) ----
DELETE FROM `creature` WHERE `guid`=5300681;
