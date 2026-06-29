-- GM test gear vendor (ICC top-tier) near Stormwind AH. Idempotent.
DELETE FROM `creature` WHERE `id1`=990030;
DELETE FROM `npc_vendor` WHERE `entry`=990030;
DELETE FROM `creature_template_model` WHERE `CreatureID`=990030;
DELETE FROM `creature_template` WHERE `entry`=990030;
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (990030,"Quartiermeister der Albtraumwacht","Test-Ausruester (ICC)",80,80,35,128,1,768,7,"",0,100,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (990030,0,7330,1,1,0);
INSERT INTO `npc_vendor` (`entry`,`slot`,`item`,`maxcount`,`incrtime`,`ExtendedCost`)
 SELECT 990030,0,`entry`,0,0,0 FROM `item_template`
 WHERE `ItemLevel` BETWEEN 271 AND 277
   AND (`AllowableClass` = -1 OR (`AllowableClass` & 256) <> 0)
   AND ( (`class`=4 AND `subclass` IN (0,1)) OR (`class`=2 AND `subclass` IN (7,10,15,19)) )
   AND `InventoryType`>0;
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
 VALUES (5300691,990030,0,0,0,0,0,1,1,0,-8806,644,94.3,3.6,300,0,0,100000,0,0,0,0,0,"",0,0,"ICC Test Vendor");
