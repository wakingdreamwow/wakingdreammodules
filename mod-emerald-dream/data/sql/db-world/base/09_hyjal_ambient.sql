-- Hyjal S1 ambient: move Maldoran to WP1 front line + Cenarion druids fighting shades (immersive "constant danger").
-- Druids faction 124 (Cenarion combatant: friendly to players, hostile to faction-14 monsters). Idempotent.
SET @DRUID:=990044; SET @SHADE:=990012;

-- Maldoran (5301200) down to the WP1 threshold, near the Hueter
UPDATE `creature` SET position_x=5210,position_y=-3320,position_z=1643.5,orientation=3.9,map=1 WHERE guid=5301200;

-- speed up the relocated Q1 shade cluster respawns so the battle/quest stays supplied
UPDATE `creature` SET spawntimesecs=120 WHERE guid BETWEEN 5300683 AND 5300690;

DELETE FROM `creature` WHERE `guid` BETWEEN 5301210 AND 5301225;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@DRUID;
DELETE FROM `creature_template` WHERE `entry`=@DRUID;

-- Cenarion-Druide (ally combatant, fights shades, player-friendly)
INSERT INTO `creature_template` (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`)
VALUES (@DRUID,'Cenarion-Druide','Verteidiger Hyjals',80,80,124,0,1,0,7,'',0,8,1,1,1);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@DRUID,0,4249,1.0,1,0);

-- Battle line at WP1 (flat, verified): 6 druids interleaved with 4 extra shades -> perpetual skirmish
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301210,@DRUID,0,0,1,0,0,1,1,0,5208,-3326,1643.5,4.2,120,0,0,1,0,0,0,0,0,'',0,0,'Druid frontline'),
 (5301211,@DRUID,0,0,1,0,0,1,1,0,5202,-3328,1643.5,4.2,120,0,0,1,0,0,0,0,0,'',0,0,'Druid frontline'),
 (5301212,@DRUID,0,0,1,0,0,1,1,0,5212,-3324,1643.5,4.2,120,0,0,1,0,0,0,0,0,'',0,0,'Druid frontline'),
 (5301213,@DRUID,0,0,1,0,0,1,1,0,5206,-3332,1643.5,4.2,120,0,0,1,0,0,0,0,0,'',0,0,'Druid frontline'),
 (5301214,@DRUID,0,0,1,0,0,1,1,0,5210,-3330,1643.5,4.2,120,0,0,1,0,0,0,0,0,'',0,0,'Druid frontline'),
 (5301215,@DRUID,0,0,1,0,0,1,1,0,5200,-3326,1643.5,4.2,120,0,0,1,0,0,0,0,0,'',0,0,'Druid frontline'),
 (5301216,@SHADE,0,0,1,0,0,1,1,0,5205,-3329,1643.5,1.0,90,0,0,1,0,0,0,0,0,'',0,0,'Battle shade'),
 (5301217,@SHADE,0,0,1,0,0,1,1,0,5209,-3327,1643.5,1.0,90,0,0,1,0,0,0,0,0,'',0,0,'Battle shade'),
 (5301218,@SHADE,0,0,1,0,0,1,1,0,5203,-3331,1643.5,1.0,90,0,0,1,0,0,0,0,0,'',0,0,'Battle shade'),
 (5301219,@SHADE,0,0,1,0,0,1,1,0,5207,-3333,1643.5,1.0,90,0,0,1,0,0,0,0,0,'',0,0,'Battle shade');
