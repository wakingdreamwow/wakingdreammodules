-- Test world boss "Glutwyrm" (entry 990001) + Onyxia model + SmartAI flame breath + spawn (Coldridge Valley)
-- Idempotent: safe to re-run.
DELETE FROM `creature` WHERE `id1`=990001;
DELETE FROM `smart_scripts` WHERE `entryorguid`=990001 AND `source_type`=0;
DELETE FROM `creature_template_model` WHERE `CreatureID`=990001;
DELETE FROM `creature_template` WHERE `entry`=990001;
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`rank`,`DamageModifier`,`BaseAttackTime`,`unit_class`,`unit_flags`,`type`,`type_flags`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`flags_extra`)
VALUES (990001,'Glutwyrm','Weltboss (Test)',3,3,14,0,3,1,2000,1,0,2,0,'SmartAI',0,2100,1,1,1,0);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (990001,0,8570,1,1,0);
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
 VALUES (5300679,990001,0,0,0,0,0,1,1,0,-6424.57,242.54,410.67,3.7,60,0,0,150000,0,0,0,0,0,'',0,0,'Glutwyrm Testboss');
