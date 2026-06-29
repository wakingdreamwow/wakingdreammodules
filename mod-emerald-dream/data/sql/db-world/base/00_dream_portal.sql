-- Emerald Dream: portal warden NPC (entry 990010) + spawns.
-- Entrance = Twilight Grove (Duskwood, map 0); hub = Nordrassil (Hyjal, map 1, real terrain).
-- Idempotent: safe to re-run.
DELETE FROM `creature` WHERE `id1`=990010;
DELETE FROM `creature_template_model` WHERE `CreatureID`=990010;
DELETE FROM `creature_template` WHERE `entry`=990010;
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`ScriptName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (990010,'Hueter des Smaragdtraums','Traumwaechter',80,80,35,1,1,770,7,'','npc_dream_portal',0,50,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (990010,0,17340,1,1,0);
-- Entrance warden at Twilight Grove (Duskwood, map 0)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
 VALUES (5300680,990010,0,0,0,0,0,1,1,0,-10428.8,-392.2,44.1,0.93,300,0,0,5000,0,0,0,0,0,'',0,0,'Dream Portal - Twilight Grove entrance');
-- Hub warden at Nordrassil (Hyjal, map 1)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
 VALUES (5300681,990010,0,0,1,0,0,1,1,0,5372.7,-3378.7,1655.5,3.9,300,0,0,5000,0,0,0,0,0,'',0,0,'Dream Portal - Hyjal hub');
DELETE FROM `creature` WHERE `guid`=5300680; -- entrance warden replaced by lore portal keeper 990061
DELETE FROM `creature` WHERE `guid`=5300681; -- hub return-warden replaced by lore keeper 990063
